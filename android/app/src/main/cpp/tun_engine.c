#include "tun_engine.h"
#include "bypass.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <errno.h>
#include <arpa/inet.h>
#include <netinet/ip.h>
#include <netinet/tcp.h>
#include <android/log.h>

#define TAG "NeoTUN"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO,  TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

#define PKT_BUF 65535
#define BADSEQ_INC ((uint32_t)(-10000))

static volatile int g_running = 0;
static int          g_tun_fd  = -1;
static int          g_fake_ttl = 5;
static int          g_disorder = 1;
static pthread_t    g_thread;

/* ------------------------------------------------------------------ */
/* Вспомогательные функции работы с пакетами                          */
/* ------------------------------------------------------------------ */

static uint16_t ip_checksum(const void *buf, size_t len) {
    const uint16_t *p = (const uint16_t *)buf;
    uint32_t sum = 0;
    while (len > 1) { sum += *p++; len -= 2; }
    if (len) sum += *(const uint8_t *)p;
    while (sum >> 16) sum = (sum & 0xFFFF) + (sum >> 16);
    return (uint16_t)~sum;
}

static uint16_t tcp_checksum(const struct iphdr *ip, const struct tcphdr *tcp,
                              const uint8_t *payload, size_t payload_len) {
    size_t tcp_len = (tcp->doff * 4) + payload_len;
    uint8_t *pseudo = malloc(12 + tcp_len);
    if (!pseudo) return 0;

    /* Pseudo header */
    memcpy(pseudo,     &ip->saddr, 4);
    memcpy(pseudo + 4, &ip->daddr, 4);
    pseudo[8] = 0;
    pseudo[9] = IPPROTO_TCP;
    pseudo[10] = (uint8_t)(tcp_len >> 8);
    pseudo[11] = (uint8_t)(tcp_len & 0xFF);
    memcpy(pseudo + 12, tcp, tcp->doff * 4);
    if (payload_len)
        memcpy(pseudo + 12 + tcp->doff * 4, payload, payload_len);

    /* Обнуляем checksum в копии TCP заголовка */
    ((struct tcphdr *)(pseudo + 12))->check = 0;

    uint16_t csum = ip_checksum(pseudo, 12 + tcp_len);
    free(pseudo);
    return csum;
}

/*
 * Записать пакет в TUN.
 * Строим IP+TCP+payload из компонентов.
 */
static void write_segment(int fd,
                           const struct iphdr  *ip,
                           const struct tcphdr *tcp,
                           const uint8_t       *payload,
                           size_t               payload_len,
                           uint32_t             seq_override,
                           uint8_t              ttl_override)
{
    size_t ip_hlen  = ip->ihl * 4;
    size_t tcp_hlen = tcp->doff * 4;
    size_t total    = ip_hlen + tcp_hlen + payload_len;

    uint8_t *pkt = malloc(total);
    if (!pkt) return;

    memcpy(pkt, ip,  ip_hlen);
    memcpy(pkt + ip_hlen, tcp, tcp_hlen);
    if (payload_len)
        memcpy(pkt + ip_hlen + tcp_hlen, payload, payload_len);

    struct iphdr  *nip  = (struct iphdr  *)pkt;
    struct tcphdr *ntcp = (struct tcphdr *)(pkt + ip_hlen);

    nip->tot_len = htons((uint16_t)total);
    nip->check   = 0;
    if (ttl_override) nip->ttl = ttl_override;
    if (seq_override) ntcp->seq = htonl(seq_override);
    ntcp->psh = 0;
    ntcp->check = 0;

    nip->check  = ip_checksum(pkt, ip_hlen);
    ntcp->check = tcp_checksum(nip, ntcp, payload, payload_len);

    write(fd, pkt, total);
    free(pkt);
}

static void send_fake(int fd,
                      const struct iphdr  *ip,
                      const struct tcphdr *tcp,
                      size_t               payload_len,
                      uint32_t             base_seq,
                      uint8_t              fake_ttl)
{
    uint8_t *junk = malloc(payload_len);
    if (!junk) return;
    junk[0] = 0x00;
    for (size_t i = 1; i < payload_len; i++) junk[i] = (uint8_t)(i & 0xFF);

    write_segment(fd, ip, tcp, junk, payload_len,
                  base_seq + BADSEQ_INC, fake_ttl);
    free(junk);
}

/*
 * Десинхронизация: FAKEDDISORDER или FAKEDSPLIT.
 * Та же логика что и в windivert_engine.c.
 */
static void desync_send(int fd,
                         const struct iphdr  *ip,
                         const struct tcphdr *tcp,
                         const uint8_t       *payload,
                         size_t               payload_len,
                         size_t               split_at,
                         int                  disorder,
                         int                  fake_ttl)
{
    if (split_at == 0 || split_at >= payload_len) return;

    uint32_t base_seq = ntohl(tcp->seq);
    uint32_t seq2     = base_seq + (uint32_t)split_at;

    if (disorder) {
        if (fake_ttl > 0)
            send_fake(fd, ip, tcp, payload_len - split_at, seq2, (uint8_t)fake_ttl);
        write_segment(fd, ip, tcp, payload + split_at, payload_len - split_at, seq2, 0);
        usleep(1000);
        if (fake_ttl > 0) {
            send_fake(fd, ip, tcp, payload_len - split_at, seq2, (uint8_t)fake_ttl);
            send_fake(fd, ip, tcp, split_at, base_seq, (uint8_t)fake_ttl);
        }
        write_segment(fd, ip, tcp, payload, split_at, base_seq, 0);
        if (fake_ttl > 0)
            send_fake(fd, ip, tcp, split_at, base_seq, (uint8_t)fake_ttl);
    } else {
        if (fake_ttl > 0)
            send_fake(fd, ip, tcp, split_at, base_seq, (uint8_t)fake_ttl);
        write_segment(fd, ip, tcp, payload, split_at, base_seq, 0);
        usleep(1000);
        if (fake_ttl > 0) {
            send_fake(fd, ip, tcp, split_at, base_seq, (uint8_t)fake_ttl);
            send_fake(fd, ip, tcp, payload_len - split_at, seq2, (uint8_t)fake_ttl);
        }
        write_segment(fd, ip, tcp, payload + split_at, payload_len - split_at, seq2, 0);
        if (fake_ttl > 0)
            send_fake(fd, ip, tcp, payload_len - split_at, seq2, (uint8_t)fake_ttl);
    }
}

/* ------------------------------------------------------------------ */
/* Основной поток обработки пакетов                                    */
/* ------------------------------------------------------------------ */

static void *engine_thread(void *arg) {
    (void)arg;
    uint8_t buf[PKT_BUF];

    while (g_running) {
        ssize_t n = read(g_tun_fd, buf, sizeof(buf));
        if (n <= 0) {
            if (!g_running) break;
            continue;
        }

        if ((size_t)n < sizeof(struct iphdr)) {
            write(g_tun_fd, buf, n);
            continue;
        }

        struct iphdr *ip = (struct iphdr *)buf;

        /* Только IPv4 TCP */
        if (ip->version != 4 || ip->protocol != IPPROTO_TCP) {
            write(g_tun_fd, buf, n);
            continue;
        }

        size_t ip_hlen = ip->ihl * 4;
        if ((size_t)n < ip_hlen + sizeof(struct tcphdr)) {
            write(g_tun_fd, buf, n);
            continue;
        }

        struct tcphdr *tcp = (struct tcphdr *)(buf + ip_hlen);
        size_t tcp_hlen    = tcp->doff * 4;
        size_t total_hdr   = ip_hlen + tcp_hlen;

        if ((size_t)n <= total_hdr) {
            write(g_tun_fd, buf, n);
            continue;
        }

        uint8_t *payload     = buf + total_hdr;
        size_t   payload_len = (size_t)n - total_hdr;

        /* Только TLS ClientHello на порт 443 */
        if (ntohs(tcp->dest) != 443 || payload_len < 5 || payload[0] != 0x16) {
            write(g_tun_fd, buf, n);
            continue;
        }

        /* Извлекаем SNI */
        int sni_off = find_sni_offset(payload, payload_len);
        char sni[256] = {0};
        if (sni_off > 0 && sni_off < (int)payload_len) {
            int sni_len = (payload[sni_off-2] << 8) | payload[sni_off-1];
            if (sni_len > 0 && sni_off + sni_len <= (int)payload_len) {
                if (sni_len >= (int)sizeof(sni)) sni_len = sizeof(sni) - 1;
                memcpy(sni, payload + sni_off, sni_len);
            }
        }

        if (!should_bypass(sni)) {
            write(g_tun_fd, buf, n);
            continue;
        }

        int split_at = sni_off > 0 ? sni_off : 5;
        if (split_at <= 0 || split_at >= (int)payload_len) {
            write(g_tun_fd, buf, n);
            continue;
        }

        LOGI("bypass [%s] port=443 split@%d disorder=%d fake_ttl=%d",
             sni[0] ? sni : "?", split_at, g_disorder, g_fake_ttl);

        desync_send(g_tun_fd, ip, tcp, payload, payload_len,
                    (size_t)split_at, g_disorder, g_fake_ttl);
        /* Оригинал не пишем — уже отправили части */
    }

    return NULL;
}

/* ------------------------------------------------------------------ */
/* Публичный API                                                        */
/* ------------------------------------------------------------------ */

int tun_engine_start(int tun_fd, int fake_ttl, int disorder) {
    if (g_running) return 0;
    g_tun_fd   = tun_fd;
    g_fake_ttl = fake_ttl;
    g_disorder = disorder;
    g_running  = 1;

    if (pthread_create(&g_thread, NULL, engine_thread, NULL) != 0) {
        g_running = 0;
        return -1;
    }
    LOGI("TUN engine started (fake_ttl=%d disorder=%d)", fake_ttl, disorder);
    return 0;
}

void tun_engine_stop(void) {
    if (!g_running) return;
    g_running = 0;
    pthread_join(g_thread, NULL);
    LOGI("TUN engine stopped");
}
