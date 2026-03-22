#!/usr/bin/env python3
"""
Replace hev-jni.c with a clean version that:
- Has safe JNI_OnLoad (no FindClass crash)
- Exports methods for com.neotun.dpi.DpiVpnService
Also patches Android.mk to add -DANDROID.
"""
import sys, os

# ── 1. Android.mk: add -DANDROID ─────────────────────────────────────────────
mk_path = "android/app/src/main/jni/hev-socks5-tunnel/Android.mk"
try:
    mk = open(mk_path).read()
    if "-DANDROID" not in mk:
        mk = mk.replace(
            "LOCAL_CFLAGS += -DFD_SET_DEFINED -DSOCKLEN_T_DEFINED -DENABLE_LIBRARY",
            "LOCAL_CFLAGS += -DFD_SET_DEFINED -DSOCKLEN_T_DEFINED -DENABLE_LIBRARY -DANDROID",
        )
        open(mk_path, "w").write(mk)
        print("Patched Android.mk: added -DANDROID")
    else:
        print("Android.mk: -DANDROID already present")
except FileNotFoundError:
    print(f"WARNING: {mk_path} not found")

# ── 2. Replace hev-jni.c entirely ────────────────────────────────────────────
jni_path = "android/app/src/main/jni/hev-socks5-tunnel/src/hev-jni.c"
if not os.path.exists(jni_path):
    print(f"ERROR: {jni_path} not found"); sys.exit(1)

NEW_JNI = r"""/*
 * hev-jni.c — patched for NeoTUN (com.neotun.dpi)
 * Exports TProxyStartService / TProxyStopService for DpiVpnService.
 */
#ifdef ANDROID

#include <jni.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>

#include "hev-main.h"
#include "hev-jni.h"

typedef struct {
    char *path;
    int   fd;
} ThreadData;

static int            is_working;
static JavaVM        *java_vm;
static pthread_t      work_thread;
static pthread_mutex_t mutex;
static pthread_key_t  current_jni_env;

static void
detach_current_thread (void *env)
{
    (*java_vm)->DetachCurrentThread (java_vm);
}

jint
JNI_OnLoad (JavaVM *vm, void *reserved)
{
    JNIEnv *env = NULL;

    java_vm = vm;
    if (JNI_OK != (*vm)->GetEnv (vm, (void **)&env, JNI_VERSION_1_4))
        return 0;

    pthread_key_create (&current_jni_env, detach_current_thread);
    pthread_mutex_init (&mutex, NULL);

    return JNI_VERSION_1_4;
}

static void *
thread_handler (void *data)
{
    ThreadData *td = data;
    hev_socks5_tunnel_main (td->path, td->fd);
    free (td->path);
    free (td);
    return NULL;
}

static void
do_start (JNIEnv *env, jstring config_path, jint fd)
{
    const char *bytes;
    ThreadData *td;
    int res;

    pthread_mutex_lock (&mutex);
    if (is_working) goto exit;

    td = malloc (sizeof (ThreadData));
    if (!td) goto exit;
    td->fd = fd;

    bytes = (*env)->GetStringUTFChars (env, config_path, NULL);
    td->path = strdup (bytes);
    (*env)->ReleaseStringUTFChars (env, config_path, bytes);

    res = pthread_create (&work_thread, NULL, thread_handler, td);
    if (res != 0) { free (td->path); free (td); goto exit; }

    is_working = 1;
exit:
    pthread_mutex_unlock (&mutex);
}

static void
do_stop (void)
{
    pthread_mutex_lock (&mutex);
    if (!is_working) goto exit;
    hev_socks5_tunnel_quit ();
    pthread_join (work_thread, NULL);
    is_working = 0;
exit:
    pthread_mutex_unlock (&mutex);
}

static jlongArray
do_stats (JNIEnv *env)
{
    size_t tx_p, rx_p, tx_b, rx_b;
    jlong  arr[4];
    jlongArray res;

    hev_socks5_tunnel_stats (&tx_p, &tx_b, &rx_p, &rx_b);
    arr[0] = tx_p; arr[1] = tx_b; arr[2] = rx_p; arr[3] = rx_b;
    res = (*env)->NewLongArray (env, 4);
    (*env)->SetLongArrayRegion (env, res, 0, 4, arr);
    return res;
}

/* ── Exports for com.neotun.dpi.DpiVpnService ─────────────────────────────── */

JNIEXPORT void JNICALL
Java_com_neotun_dpi_DpiVpnService_TProxyStartService (JNIEnv *env, jobject thiz,
                                                       jstring config_path, jint fd)
{
    (void)thiz;
    do_start (env, config_path, fd);
}

JNIEXPORT void JNICALL
Java_com_neotun_dpi_DpiVpnService_TProxyStopService (JNIEnv *env, jobject thiz)
{
    (void)env; (void)thiz;
    do_stop ();
}

JNIEXPORT jlongArray JNICALL
Java_com_neotun_dpi_DpiVpnService_TProxyGetStats (JNIEnv *env, jobject thiz)
{
    (void)thiz;
    return do_stats (env);
}

#endif /* ANDROID */
"""

open(jni_path, "w").write(NEW_JNI)
print("Replaced hev-jni.c with clean NeoTUN version")
