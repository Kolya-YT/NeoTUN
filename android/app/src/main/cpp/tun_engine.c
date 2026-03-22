/*
 * NeoTUN Android — TUN engine (minimal TCP proxy)
 *
 * Читает IP пакеты из TUN fd.
 * Для каждого TCP:443 SYN — создаёт поток-прокси:
 *   1. Отвечает SYN-ACK клиенту через TUN
 *   2. Ждёт данных от клиента (ACK+PSH с TLS ClientHello)
 *   3. Подключается к реальному серверу через protect()
 *   4. Применяет FAKEDDISORDER split на ClientHello
 *   5. Двунаправленный relay: TUN ↔ real socket
 *
 * Для передачи данных между tun_reader и conn_thread используем socketpair.
 */

#include "tun_engine.h"
#include "bypass.h"

#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <errno.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <android/log.h>

#define TAG  "NeoTUN"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO,  TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

#define BUF_SIZE 65536

/* ------------------------------------------------------------------ */
/* Globals                                                              */
/* ------------------------------------------------------------------ */

static volatile int  g_running  = 0;
static int           g_tun_fd   = -1;
static int           g_fake_ttl = 5;
static int           g_disorder = 1;
static pthread_t     g_tun_thread;

static JavaVM  *g_jvm     = NULL;
static jobject  g_service = NULL;

/* ------------------------------------------------------------------ */
/* protect() via JNI                                                    */
/* ------------------------------------------------------------------ */

static int protect_socket(int fd) {
    if (!g_jvm || !g_service) return 0;
    JNIEnv *env = NULL;
    int attached = 0;
    if ((*g_jvm)->GetEnv(g_jvm, (void**)&env, JNI_VERSION_1_6) != JNI_OK) {
        (*g_jvm)->AttachCurrentThread(g_jvm, &env, NULL);
        attached = 1;
    }
    jclass cls = (*env)->GetObjectClass(env, g_service);
    jmethodID mid = (*env)->GetMethodID(env, cls, "protect", "(I)Z");
    jboolean ok = (*env)->CallBooleanMethod(env, g_service, mid, (jint)fd);
    (*env)->DeleteLocalRef(env, cls);
    if (attached) (*g_jvm)->DetachCurrentThread(g_jvm);
    return ok ? 0 : -1;
}

/* ------------------------------------------------------------------ */
/* IP/TCP helpers                                                       */
/* ------------------------------------------------------------------ */

static uint16_t checksum16(const void *buf, size_t len) {
    const uint16_t *p = buf;
    uint32_t s = 0;
    while (len > 1) { s += *p++; len -= 2; }
    if (len) s += *(const uint8_t*)p;
    while (s >> 16) s = (s & 0xffff) + (s >> 16);
    return (uint16_t)~s;
}

static uint16_t tcp_csum(uint32_t sip, uint32_t dip,
                          const uint8_t *tcp, size_t tcp_len) {
    uint8_t ph[12];
    memcpy(ph,   &sip, 4);
    memcpy(ph+4, &dip, 4);
    ph[8] = 0; ph[9] = 6;
    uint16_t tl = htons((uint16_t)tcp_len);
    memcpy(ph+10, &tl, 2);
    uint32_t s = 0;
    const uint16_t *p = (const uint16_t*)ph;
    for (int i = 0; i < 6; i++) s += p[i];
    p = (const uint16_t*)tcp;
    size_t rem = tcp_len;
    while (rem > 1) { s += *p++; rem -= 2; }
    if (rem) s += *(const uint8_t*)p;
    while (s >> 16) s = (s & 0xffff) + (s >> 16);
    return (uint16_t)~s;
}

/* Build IP+TCP packet and write to TUN */
static void tun_send(int tun_fd,
                     uint32_t sip, uint16_t sport,
                     uint32_t dip, uint16_t dport,
                     uint32_t seq, uint32_t ack,
                     uint8_t flags,
                     const uint8_t *data, size_t dlen) {
    size_t total = 40 + dlen;
    uint8_t *pkt = calloc(1, total);
    if (!pkt) return;

    /* IPv4 */
    pkt[0] = 0x45;
    uint16_t tot = htons((uint16_t)total);
    memcpy(pkt+2, &tot, 2);
    pkt[8] = 64;
    pkt[9] = 6; /* TCP */
    memcpy(pkt+12, &sip, 4);
    memcpy(pkt+16, &dip, 4);
    uint16_t ic = checksum16(pkt, 20);
    memcpy(pkt+10, &ic, 2);

    /* TCP */
    uint8_t *tcp = pkt + 20;
    memcpy(tcp+0, &sport, 2);
    memcpy(tcp+2, &dport, 2);
    uint32_t sn = htonl(seq), an = htonl(ack);
    memcpy(tcp+4, &sn, 4);
    memcpy(tcp+8, &an, 4);
    tcp[12] = 0x50; /* data offset = 5 */
    tcp[13] = flags;
    uint16_t win = htons(65535);
    memcpy(tcp+14, &win, 2);
    if (dlen) memcpy(tcp+20, data, dlen);
    uint16_t tc = tcp_csum(sip, dip, tcp, 20 + dlen);
    memcpy(tcp+16, &tc, 2);

    write(tun_fd, pkt, total);
    free(pkt);
}

#define F_FIN 0x01
#define F_SYN 0x02
#define F_RST 0x04
#define F_PSH 0x08
#define F_ACK 0x10

/* ------------------------------------------------------------------ */
/* Connection table — maps (src_ip, src_port) → pipe write end         */
/* ------------------------------------------------------------------ */

#define CONN_MAX 256

typedef struct {
    uint32_t cli_ip;
    uint16_t cli_port;
    int      pipe_wr; /* write end — tun_reader pushes client data here */
} ConnSlot;

static ConnSlot     g_conns[CONN_MAX];
static pthread_mutex_t g_conns_mu = PTHREAD_MUTEX_INITIALIZER;

static int conn_add(uint32_t cli_ip, uint16_t cli_port, int pipe_wr) {
    for (int i = 0; i < CONN_MAX; i++) {
        if (!g_conns[i].pipe_wr) {
            g_conns[i].cli_ip   = cli_ip;
            g_conns[i].cli_port = cli_port;
            g_conns[i].pipe_wr  = pipe_wr;
            return 0;
        }
    }
    return -1;
}

static int conn_get_pipe(uint32_t cli_ip, uint16_t cli_port) {
    for (int i = 0; i < CONN_MAX; i++) {
        if (g_conns[i].cli_ip == cli_ip && g_conns[i].cli_port == cli_port)
            return g_conns[i].pipe_wr;
    }
    return -1;
}

static void conn_del(uint32_t cli_ip, uint16_t cli_port) {
    for (int i = 0; i < CONN_MAX; i++) {
        if (g_conns[i].cli_ip == cli_ip && g_conns[i].cli_port == cli_port) {
            g_conns[i].pipe_wr  = 0;
            g_conns[i].cli_ip   = 0;
            g_conns[i].cli_port = 0;
            return;
        }
    }
}

/* ------------------------------------------------------------------ */
/* Per-connection thread                                                */
/* ------------------------------------------------------------------ */

typedef struct {
    int      tun_fd;
    uint32_t cli_ip;
    uint16_t cli_port;
    uint32_t srv_ip;
    uint16_t srv_port;
    uint32_t cli_seq;   /* expected next seq from client */
    int      pipe_rd;   /* read end — receives client payload bytes */
    int      fake_ttl;
    int      disorder;
} ConnArgs;

static void apply_bypass(int sfd, const uint8_t *data, size_t len, int disorder) {
    if (len > 5 && data[0] == 0x16) {
        int sni_off = find_sni_offset(data, len);
        size_t split = (sni_off > 2) ? (size_t)sni_off : 5;

        char sni[256] = {0};
        if (sni_off > 2 && sni_off < (int)len) {
            int sni_len = (data[sni_off-2]<<8)|data[sni_off-1];
            if (sni_len > 0 && sni_off+sni_len <= (int)len) {
                int n = sni_len < 255 ? sni_len : 255;
                memcpy(sni, data+sni_off, n);
            }
        }

        if (!should_bypass(sni)) {
            send(sfd, data, len, 0);
            return;
        }

        LOGI("bypass [%s] split@%zu disorder=%d", sni[0]?sni:"?", split, disorder);

        if (disorder) {
            uint8_t *junk = calloc(1, len - split);
            if (junk) {
                send(sfd, junk, len - split, MSG_MORE);
                free(junk);
            }
            send(sfd, data + split, len - split, MSG_MORE);
            usleep(1000);
            send(sfd, data, split, 0);
        } else {
            send(sfd, data, split, MSG_MORE);
            usleep(1000);
            send(sfd, data + split, len - split, 0);
        }
    } else {
        send(sfd, data, len, 0);
    }
}

static void *conn_thread(void *arg) {
    ConnArgs *ca = (ConnArgs*)arg;
    uint8_t buf[BUF_SIZE];
    int sfd = -1;

    /* 1. Send SYN-ACK to client */
    uint32_t srv_isn = 0xDEAD0000 ^ (uint32_t)(uintptr_t)ca;
    uint32_t srv_seq = srv_isn;
    tun_send(ca->tun_fd,
             ca->srv_ip, ca->srv_port,
             ca->cli_ip, ca->cli_port,
             srv_seq, ca->cli_seq,
             F_SYN | F_ACK, NULL, 0);
    srv_seq++;

    /* 2. Wait for first data from client via pipe (ACK + PSH) */
    struct timeval tv = {10, 0};
    fd_set fds;
    FD_ZERO(&fds); FD_SET(ca->pipe_rd, &fds);
    if (select(ca->pipe_rd+1, &fds, NULL, NULL, &tv) <= 0) goto done;

    ssize_t n = read(ca->pipe_rd, buf, sizeof(buf));
    if (n <= 0) goto done;

    /* 3. Connect to real server */
    sfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sfd < 0) goto done;
    protect_socket(sfd);

    struct timeval stv = {15, 0};
    setsockopt(sfd, SOL_SOCKET, SO_RCVTIMEO, &stv, sizeof(stv));
    setsockopt(sfd, SOL_SOCKET, SO_SNDTIMEO, &stv, sizeof(stv));

    {
        struct sockaddr_in dst = {0};
        dst.sin_family      = AF_INET;
        dst.sin_addr.s_addr = ca->srv_ip;
        dst.sin_port        = ca->srv_port;
        if (connect(sfd, (struct sockaddr*)&dst, sizeof(dst)) != 0) {
            LOGE("connect failed: %s", strerror(errno));
            goto done;
        }
    }

    /* 4. Apply bypass on first packet */
    apply_bypass(sfd, buf, (size_t)n, ca->disorder);
    ca->cli_seq += (uint32_t)n;

    /* ACK the client data */
    tun_send(ca->tun_fd,
             ca->srv_ip, ca->srv_port,
             ca->cli_ip, ca->cli_port,
             srv_seq, ca->cli_seq,
             F_ACK, NULL, 0);

    /* 5. Bidirectional relay */
    int maxfd = ca->pipe_rd > sfd ? ca->pipe_rd : sfd;
    while (g_running) {
        FD_ZERO(&fds);
        FD_SET(ca->pipe_rd, &fds);
        FD_SET(sfd, &fds);
        stv.tv_sec = 60; stv.tv_usec = 0;

        if (select(maxfd+1, &fds, NULL, NULL, &stv) <= 0) break;

        /* Client → server */
        if (FD_ISSET(ca->pipe_rd, &fds)) {
            n = read(ca->pipe_rd, buf, sizeof(buf));
            if (n <= 0) break;
            if (send(sfd, buf, (size_t)n, 0) <= 0) break;
            ca->cli_seq += (uint32_t)n;
            tun_send(ca->tun_fd,
                     ca->srv_ip, ca->srv_port,
                     ca->cli_ip, ca->cli_port,
                     srv_seq, ca->cli_seq,
                     F_ACK, NULL, 0);
        }

        /* Server → client */
        if (FD_ISSET(sfd, &fds)) {
            n = recv(sfd, buf, sizeof(buf), 0);
            if (n <= 0) break;
            tun_send(ca->tun_fd,
                     ca->srv_ip, ca->srv_port,
                     ca->cli_ip, ca->cli_port,
                     srv_seq, ca->cli_seq,
                     F_PSH | F_ACK,
                     buf, (size_t)n);
            srv_seq += (uint32_t)n;
        }
    }

    /* FIN */
    tun_send(ca->tun_fd,
             ca->srv_ip, ca->srv_port,
             ca->cli_ip, ca->cli_port,
             srv_seq, ca->cli_seq,
             F_FIN | F_ACK, NULL, 0);

done:
    pthread_mutex_lock(&g_conns_mu);
    conn_del(ca->cli_ip, ca->cli_port);
    pthread_mutex_unlock(&g_conns_mu);

    if (sfd >= 0) close(sfd);
    close(ca->pipe_rd);
    free(ca);
    return NULL;
}

/* ------------------------------------------------------------------ */
/* TUN reader thread                                                    */
/* ------------------------------------------------------------------ */

static void handle_packet(uint8_t *pkt, size_t len) {
    if (len < 40) return;
    if ((pkt[0] >> 4) != 4) return;
    if (pkt[9] != 6) return; /* TCP only */

    uint8_t ihl = (pkt[0] & 0x0f) * 4;
    if (len < (size_t)(ihl + 20)) return;

    uint32_t sip, dip;
    memcpy(&sip, pkt+12, 4);
    memcpy(&dip, pkt+16, 4);

    uint8_t *tcp = pkt + ihl;
    uint16_t sport, dport;
    memcpy(&sport, tcp+0, 2);
    memcpy(&dport, tcp+2, 2);

    uint32_t seq;
    memcpy(&seq, tcp+4, 4); seq = ntohl(seq);

    uint8_t thl   = ((tcp[12] >> 4) & 0x0f) * 4;
    uint8_t flags = tcp[13];

    size_t doff = ihl + thl;
    size_t dlen = (len > doff) ? len - doff : 0;
    uint8_t *data = pkt + doff;

    /* Only intercept port 443 */
    if (ntohs(dport) != 443) return;

    if (flags & F_RST) {
        pthread_mutex_lock(&g_conns_mu);
        conn_del(sip, sport);
        pthread_mutex_unlock(&g_conns_mu);
        return;
    }

    if (flags & F_SYN) {
        /* New connection */
        int pipefd[2];
        if (pipe(pipefd) != 0) return;

        ConnArgs *ca = calloc(1, sizeof(ConnArgs));
        ca->tun_fd   = g_tun_fd;
        ca->cli_ip   = sip;
        ca->cli_port = sport;
        ca->srv_ip   = dip;
        ca->srv_port = dport;
        ca->cli_seq  = seq + 1;
        ca->pipe_rd  = pipefd[0];
        ca->fake_ttl = g_fake_ttl;
        ca->disorder = g_disorder;

        pthread_mutex_lock(&g_conns_mu);
        if (conn_add(sip, sport, pipefd[1]) != 0) {
            pthread_mutex_unlock(&g_conns_mu);
            close(pipefd[0]); close(pipefd[1]);
            free(ca);
            return;
        }
        pthread_mutex_unlock(&g_conns_mu);

        pthread_t t;
        pthread_attr_t attr;
        pthread_attr_init(&attr);
        pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
        pthread_create(&t, &attr, conn_thread, ca);
        pthread_attr_destroy(&attr);
        return;
    }

    /* Data or ACK — forward to connection thread via pipe */
    if (dlen > 0) {
        pthread_mutex_lock(&g_conns_mu);
        int pw = conn_get_pipe(sip, sport);
        pthread_mutex_unlock(&g_conns_mu);
        if (pw > 0) write(pw, data, dlen);
    }
}

static void *tun_reader_thread(void *arg) {
    (void)arg;
    uint8_t buf[BUF_SIZE];
    LOGI("TUN reader started fd=%d", g_tun_fd);

    while (g_running) {
        fd_set fds;
        FD_ZERO(&fds);
        FD_SET(g_tun_fd, &fds);
        struct timeval tv = {1, 0};
        int r = select(g_tun_fd+1, &fds, NULL, NULL, &tv);
        if (r < 0) { if (errno == EINTR) continue; break; }
        if (r == 0) continue;

        ssize_t n = read(g_tun_fd, buf, sizeof(buf));
        if (n <= 0) { if (errno == EINTR) continue; break; }

        handle_packet(buf, (size_t)n);
    }

    LOGI("TUN reader stopped");
    return NULL;
}

/* ------------------------------------------------------------------ */
/* Public API                                                           */
/* ------------------------------------------------------------------ */

void tun_engine_set_jvm(JavaVM *jvm, jobject service) {
    g_jvm     = jvm;
    g_service = service;
}

int tun_engine_start(int tun_fd, int fake_ttl, int disorder) {
    if (g_running) return 0;
    g_tun_fd   = tun_fd;
    g_fake_ttl = fake_ttl;
    g_disorder = disorder;
    g_running  = 1;
    memset(g_conns, 0, sizeof(g_conns));

    if (pthread_create(&g_tun_thread, NULL, tun_reader_thread, NULL) != 0) {
        g_running = 0;
        return -1;
    }
    LOGI("TUN engine started fd=%d fake_ttl=%d disorder=%d",
         tun_fd, fake_ttl, disorder);
    return 0;
}

void tun_engine_stop(void) {
    if (!g_running) return;
    g_running = 0;
    pthread_join(g_tun_thread, NULL);
    LOGI("TUN engine stopped");
}
