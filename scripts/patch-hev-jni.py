#!/usr/bin/env python3
"""
Patch hev-jni.c in hev-socks5-tunnel submodule to export JNI symbols
for com.neotun.dpi.DpiVpnService instead of the default hev/htproxy/TProxyService.
"""
import os, sys

TARGET = os.path.join(
    os.path.dirname(__file__),
    "..", "android", "app", "src", "main", "jni",
    "hev-socks5-tunnel", "src", "hev-jni.c"
)
TARGET = os.path.normpath(TARGET)

CONTENT = r"""/*
 * hev-jni.c — NeoTUN patched build
 * Exports TProxyStartService / TProxyStopService for com.neotun.dpi.DpiVpnService
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

static int             is_working;
static JavaVM         *java_vm;
static pthread_t       work_thread;
static pthread_mutex_t mutex;
static pthread_key_t   current_jni_env;

static void
detach_current_thread(void *env)
{
    (*java_vm)->DetachCurrentThread(java_vm);
}

jint
JNI_OnLoad(JavaVM *vm, void *reserved)
{
    JNIEnv *env = NULL;

    java_vm = vm;
    if (JNI_OK != (*vm)->GetEnv(vm, (void **)&env, JNI_VERSION_1_4))
        return 0;

    pthread_key_create(&current_jni_env, detach_current_thread);
    pthread_mutex_init(&mutex, NULL);

    return JNI_VERSION_1_4;
}

static void *
thread_handler(void *data)
{
    ThreadData *td = (ThreadData *)data;
    hev_socks5_tunnel_main(td->path, td->fd);
    free(td->path);
    free(td);
    return NULL;
}

JNIEXPORT void JNICALL
Java_com_neotun_dpi_DpiVpnService_TProxyStartService(JNIEnv *env, jobject thiz,
                                                      jstring config_path, jint fd)
{
    const char *bytes;
    ThreadData *td;
    int res;

    (void)thiz;

    pthread_mutex_lock(&mutex);
    if (is_working) goto exit;

    td = (ThreadData *)malloc(sizeof(ThreadData));
    if (!td) goto exit;
    td->fd = (int)fd;

    bytes = (*env)->GetStringUTFChars(env, config_path, NULL);
    td->path = strdup(bytes);
    (*env)->ReleaseStringUTFChars(env, config_path, bytes);

    res = pthread_create(&work_thread, NULL, thread_handler, td);
    if (res != 0) { free(td->path); free(td); goto exit; }

    is_working = 1;
exit:
    pthread_mutex_unlock(&mutex);
}

JNIEXPORT void JNICALL
Java_com_neotun_dpi_DpiVpnService_TProxyStopService(JNIEnv *env, jobject thiz)
{
    (void)env; (void)thiz;

    pthread_mutex_lock(&mutex);
    if (!is_working) goto exit;
    hev_socks5_tunnel_quit();
    pthread_join(work_thread, NULL);
    is_working = 0;
exit:
    pthread_mutex_unlock(&mutex);
}

JNIEXPORT jlongArray JNICALL
Java_com_neotun_dpi_DpiVpnService_TProxyGetStats(JNIEnv *env, jobject thiz)
{
    size_t tx_p, rx_p, tx_b, rx_b;
    jlong  arr[4];
    jlongArray res;

    (void)thiz;

    hev_socks5_tunnel_stats(&tx_p, &tx_b, &rx_p, &rx_b);
    arr[0] = (jlong)tx_p;
    arr[1] = (jlong)tx_b;
    arr[2] = (jlong)rx_p;
    arr[3] = (jlong)rx_b;

    res = (*env)->NewLongArray(env, 4);
    (*env)->SetLongArrayRegion(env, res, 0, 4, arr);
    return res;
}

#endif /* ANDROID */
"""

with open(TARGET, "w", newline="\n") as f:
    f.write(CONTENT)

print(f"Patched: {TARGET}")
