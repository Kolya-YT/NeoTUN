#include <jni.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <android/log.h>

#include "bypass.h"
#include "socks5.h"
#include "utils.h"

#define TAG "NeoTUN-proxy"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO,  TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

static volatile int  g_running   = 0;
static int           g_server_fd = -1;
static pthread_t     g_thread;
static bypass_opts_t g_opts;

/* ── VpnService.protect() callback ─────────────────────────────────────────── */
static JavaVM   *g_jvm     = NULL;
static jobject   g_service = NULL;  /* global ref to DpiVpnService instance */
static jmethodID g_protect = NULL;

/*
 * Called from socks5.c before connect() on every outgoing socket.
 * Without this, the socket goes through TUN → infinite loop.
 */
void android_protect_socket(int fd) {
    if (!g_jvm || !g_service || !g_protect) return;

    JNIEnv *env = NULL;
    int attached = 0;
    if ((*g_jvm)->GetEnv(g_jvm, (void **)&env, JNI_VERSION_1_4) != JNI_OK) {
        (*g_jvm)->AttachCurrentThread(g_jvm, &env, NULL);
        attached = 1;
    }
    if (!env) return;

    (*env)->CallBooleanMethod(env, g_service, g_protect, (jint)fd);

    if (attached) (*g_jvm)->DetachCurrentThread(g_jvm);
}

/* ── client thread ──────────────────────────────────────────────────────────── */
typedef struct { sock_t client; } thread_arg_t;

static void *client_thread(void *arg) {
    thread_arg_t *ta = (thread_arg_t *)arg;
    upstream_t upstream;
    memset(&upstream, 0, sizeof(upstream));
    handle_client(ta->client, &g_opts, &upstream);
    free(ta);
    return NULL;
}

static void *server_thread(void *arg) {
    (void)arg;
    LOGI("SOCKS5 proxy started on 127.0.0.1:1080");

    while (g_running) {
        struct sockaddr_in ca;
        socklen_t cl = sizeof(ca);
        int client = accept(g_server_fd, (struct sockaddr *)&ca, &cl);
        if (client < 0) break;

        set_nodelay(client);

        thread_arg_t *ta = malloc(sizeof(thread_arg_t));
        if (!ta) { close(client); continue; }
        ta->client = client;

        pthread_t t;
        pthread_attr_t attr;
        pthread_attr_init(&attr);
        pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
        pthread_create(&t, &attr, client_thread, ta);
        pthread_attr_destroy(&attr);
    }

    LOGI("SOCKS5 proxy stopped");
    return NULL;
}

/* ── JNI exports ────────────────────────────────────────────────────────────── */

JNIEXPORT jint JNICALL
Java_com_neotun_dpi_DpiVpnService_nativeStartProxy(
        JNIEnv *env, jobject thiz,
        jint split_pos, jint disorder,
        jint tlsrec_split, jint oob)
{
    if (g_running) return 0;

    /* Cache JVM + service ref + protect() method for socket protection */
    (*env)->GetJavaVM(env, &g_jvm);
    if (g_service) { (*env)->DeleteGlobalRef(env, g_service); }
    g_service = (*env)->NewGlobalRef(env, thiz);
    jclass cls = (*env)->GetObjectClass(env, thiz);
    g_protect  = (*env)->GetMethodID(env, cls, "protect", "(I)Z");

    g_opts.split_pos    = split_pos;
    g_opts.disorder     = disorder;
    g_opts.fake_ttl     = 0;
    g_opts.tlsrec_split = tlsrec_split;
    g_opts.oob          = oob;

    g_server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (g_server_fd < 0) { LOGE("socket failed"); return -1; }

    int reuse = 1;
    setsockopt(g_server_fd, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse));

    struct sockaddr_in addr = {0};
    addr.sin_family      = AF_INET;
    addr.sin_port        = htons(1080);
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);

    if (bind(g_server_fd, (struct sockaddr *)&addr, sizeof(addr)) != 0) {
        LOGE("bind failed");
        close(g_server_fd);
        g_server_fd = -1;
        return -1;
    }

    if (listen(g_server_fd, 128) != 0) {
        LOGE("listen failed");
        close(g_server_fd);
        g_server_fd = -1;
        return -1;
    }

    g_running = 1;
    pthread_create(&g_thread, NULL, server_thread, NULL);
    return 0;
}

JNIEXPORT void JNICALL
Java_com_neotun_dpi_DpiVpnService_nativeStopProxy(JNIEnv *env, jobject thiz)
{
    (void)thiz;
    if (!g_running) return;
    g_running = 0;
    if (g_server_fd >= 0) {
        shutdown(g_server_fd, SHUT_RDWR);
        close(g_server_fd);
        g_server_fd = -1;
    }
    pthread_join(g_thread, NULL);

    if (g_service) {
        (*env)->DeleteGlobalRef(env, g_service);
        g_service = NULL;
    }
    g_jvm     = NULL;
    g_protect = NULL;
}
