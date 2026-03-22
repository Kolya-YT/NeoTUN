#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <process.h>

#include "windivert.h"
#include "windivert_engine.h"
#include "bypass.h"
#include "utils.h"

/* ------------------------------------------------------------------ */
/* Состояние                                                           */
/* ------------------------------------------------------------------ */

static HANDLE          g_handle     = INVALID_HANDLE_VALUE;
static HANDLE          g_rst_handle = INVALID_HANDLE_VALUE;
static volatile int    g_running    = 0;
static HANDLE          g_thread     = NULL;
static wd_engine_opts_t g_opts;

#define PKT_BUF   65535
#define NUM_THREADS 4

/*
 * badseq_increment: смещение seq у fake-пакетов.
 * Сервер дропает пакет (seq вне окна), DPI принимает.
 * Значение -10000 — стандарт zapret.
 */
#define BADSEQ_INCREMENT  ((uint32_t)(-10000))

/* ------------------------------------------------------------------ */
/* Вспомогательные функции                                             */
/* ------------------------------------------------------------------ */

static uint8_t *tcp_payload_ptr(WINDIVERT_IPHDR  *ip,
                                 WINDIVERT_TCPHDR *tcp,
                                 UINT              pkt_len,
                                 UINT             *payload_len)
{
    UINT ip_hdr_len  = ip->HdrLength * 4;
    UINT tcp_hdr_len = tcp->HdrLength * 4;
    UINT total_hdr   = ip_hdr_len + tcp_hdr_len;
    if (total_hdr >= pkt_len) { *payload_len = 0; return NULL; }
    *payload_len = pkt_len - total_hdr;
    return (uint8_t *)ip + total_hdr;
}

/*
 * Построить TCP-сегмент из заголовков оригинала + новый payload.
 * seq_override — абсолютный seq (если 0 — берём из tcp->SeqNum).
 * ttl_override — TTL (если 0 — берём из ip->TTL).
 */
static uint8_t *build_segment(WINDIVERT_IPHDR  *ip,
                               WINDIVERT_TCPHDR *tcp,
                               const uint8_t    *payload,
                               UINT              payload_len,
                               uint32_t          seq_override,
                               uint8_t           ttl_override,
                               WINDIVERT_ADDRESS *addr,
                               UINT             *out_len)
{
    UINT ip_hdr_len  = ip->HdrLength * 4;
    UINT tcp_hdr_len = tcp->HdrLength * 4;
    UINT hdr_len     = ip_hdr_len + tcp_hdr_len;
    UINT total       = hdr_len + payload_len;

    uint8_t *pkt = (uint8_t *)malloc(total);
    if (!pkt) return NULL;

    memcpy(pkt, ip,  ip_hdr_len);
    memcpy(pkt + ip_hdr_len, tcp, tcp_hdr_len);
    if (payload_len)
        memcpy(pkt + hdr_len, payload, payload_len);

    WINDIVERT_IPHDR  *nip  = (WINDIVERT_IPHDR  *)pkt;
    WINDIVERT_TCPHDR *ntcp = (WINDIVERT_TCPHDR *)(pkt + ip_hdr_len);

    nip->Length = htons((UINT16)total);
    if (ttl_override) nip->TTL = ttl_override;

    if (seq_override)
        ntcp->SeqNum = htonl(seq_override);

    /* Убираем PSH у промежуточных сегментов */
    if (payload_len > 0)
        ntcp->Psh = 0;

    WinDivertHelperCalcChecksums(pkt, total, addr, 0);
    *out_len = total;
    return pkt;
}

/*
 * Отправить fake-сегмент: те же заголовки, мусорный payload,
 * TTL = fake_ttl (умрёт до сервера), seq смещён на BADSEQ_INCREMENT.
 * DPI видит пакет и думает что это настоящий ClientHello.
 * Сервер дропает — seq вне окна.
 */
static void send_fake(HANDLE hd,
                      WINDIVERT_IPHDR  *ip,
                      WINDIVERT_TCPHDR *tcp,
                      const uint8_t    *payload,
                      UINT              payload_len,
                      uint32_t          base_seq,
                      uint8_t           fake_ttl,
                      WINDIVERT_ADDRESS *addr)
{
    /* Мусорный payload — случайные байты, не похожие на TLS */
    uint8_t *junk = (uint8_t *)malloc(payload_len);
    if (!junk) return;
    /* Заполняем мусором — не TLS (первый байт не 0x16) */
    junk[0] = 0x00;
    for (UINT i = 1; i < payload_len; i++)
        junk[i] = (uint8_t)(i & 0xFF);

    uint32_t fake_seq = base_seq + BADSEQ_INCREMENT;
    UINT fake_len;
    uint8_t *fake = build_segment(ip, tcp, junk, payload_len,
                                  fake_seq, fake_ttl, addr, &fake_len);
    free(junk);
    if (!fake) return;
    WinDivertSend(hd, fake, fake_len, NULL, addr);
    free(fake);
}

/*
 * Основная функция десинхронизации — реализует алгоритм zapret FAKEDDISORDER:
 *
 * disorder=1, fake_ttl>0:
 *   1. fake(seg2, badseq, ttl_fake)   — DPI видит "второй" сегмент
 *   2. real(seg2)                      — настоящий второй сегмент
 *   3. fake(seg2, badseq, ttl_fake)   — ещё раз fake
 *   4. fake(seg1, badseq, ttl_fake)   — DPI видит "первый" сегмент
 *   5. real(seg1)                      — настоящий первый сегмент
 *   6. fake(seg1, badseq, ttl_fake)   — ещё раз fake
 *
 * disorder=0, fake_ttl>0 (FAKEDSPLIT):
 *   1. fake(seg1, badseq, ttl_fake)
 *   2. real(seg1)
 *   3. fake(seg1, badseq, ttl_fake)
 *   4. fake(seg2, badseq, ttl_fake)
 *   5. real(seg2)
 *   6. fake(seg2, badseq, ttl_fake)
 */
static void send_desync(HANDLE hd,
                         WINDIVERT_IPHDR  *ip,
                         WINDIVERT_TCPHDR *tcp,
                         uint8_t          *payload,
                         UINT              payload_len,
                         UINT              split_at,
                         WINDIVERT_ADDRESS *addr,
                         int               disorder,
                         int               fake_ttl)
{
    if (split_at == 0 || split_at >= payload_len) return;

    uint32_t base_seq = ntohl(tcp->SeqNum);
    uint32_t seq2     = base_seq + split_at;

    UINT len1, len2;
    uint8_t *seg1 = build_segment(ip, tcp, payload,            split_at,
                                  base_seq, 0, addr, &len1);
    uint8_t *seg2 = build_segment(ip, tcp, payload + split_at, payload_len - split_at,
                                  seq2, 0, addr, &len2);
    if (!seg1 || !seg2) { free(seg1); free(seg2); return; }

    if (disorder) {
        /*
         * FAKEDDISORDER: отправляем сегменты в обратном порядке.
         * Сначала второй (сервер буферизует), потом первый.
         * DPI не может собрать ClientHello в правильном порядке.
         */
        if (fake_ttl > 0) {
            /* fake seg2 до настоящего */
            send_fake(hd, ip, tcp, payload + split_at, payload_len - split_at,
                      seq2, (uint8_t)fake_ttl, addr);
        }
        WinDivertSend(hd, seg2, len2, NULL, addr);
        Sleep(1);
        if (fake_ttl > 0) {
            /* fake seg2 после настоящего */
            send_fake(hd, ip, tcp, payload + split_at, payload_len - split_at,
                      seq2, (uint8_t)fake_ttl, addr);
            /* fake seg1 до настоящего */
            send_fake(hd, ip, tcp, payload, split_at,
                      base_seq, (uint8_t)fake_ttl, addr);
        }
        WinDivertSend(hd, seg1, len1, NULL, addr);
        if (fake_ttl > 0) {
            /* fake seg1 после настоящего */
            send_fake(hd, ip, tcp, payload, split_at,
                      base_seq, (uint8_t)fake_ttl, addr);
        }
    } else {
        /*
         * FAKEDSPLIT: обычный порядок, но с fake-пакетами вокруг.
         */
        if (fake_ttl > 0) {
            send_fake(hd, ip, tcp, payload, split_at,
                      base_seq, (uint8_t)fake_ttl, addr);
        }
        WinDivertSend(hd, seg1, len1, NULL, addr);
        Sleep(1);
        if (fake_ttl > 0) {
            send_fake(hd, ip, tcp, payload, split_at,
                      base_seq, (uint8_t)fake_ttl, addr);
            send_fake(hd, ip, tcp, payload + split_at, payload_len - split_at,
                      seq2, (uint8_t)fake_ttl, addr);
        }
        WinDivertSend(hd, seg2, len2, NULL, addr);
        if (fake_ttl > 0) {
            send_fake(hd, ip, tcp, payload + split_at, payload_len - split_at,
                      seq2, (uint8_t)fake_ttl, addr);
        }
    }

    free(seg1);
    free(seg2);
}

/*
 * Извлечь SNI-строку из TLS ClientHello.
 */
static int extract_sni_string(const uint8_t *payload, UINT payload_len,
                               char *out_sni, int out_size)
{
    int offset = find_sni_offset(payload, (size_t)payload_len);
    if (offset < 5 || offset >= (int)payload_len) return 0;

    int sni_len = (payload[offset - 2] << 8) | payload[offset - 1];
    if (sni_len <= 0 || offset + sni_len > (int)payload_len) return 0;
    if (sni_len >= out_size) sni_len = out_size - 1;
    memcpy(out_sni, payload + offset, sni_len);
    out_sni[sni_len] = '\0';
    return sni_len;
}

/*
 * Домены которые НЕ нужно трогать.
 * Discord использует WebSocket — split ломает его handshake.
 */
static const char *NO_TOUCH[] = {
    "discord.com",
    "discordapp.com",
    "discordapp.net",
    "discord.gg",
    "discord.media",
    "discordcdn.com",
    NULL
};

static int should_bypass(const char *sni)
{
    if (!sni || sni[0] == '\0') return 1;

    size_t sni_len = strlen(sni);
    for (int i = 0; NO_TOUCH[i]; i++) {
        const char *suffix = NO_TOUCH[i];
        size_t suf_len = strlen(suffix);
        if (sni_len >= suf_len) {
            const char *tail = sni + sni_len - suf_len;
            if (strcmp(tail, suffix) == 0 &&
                (tail == sni || *(tail - 1) == '.'))
                return 0;
        }
    }
    return 1;
}

/* ------------------------------------------------------------------ */
/* Потоки                                                              */
/* ------------------------------------------------------------------ */

static unsigned __stdcall engine_thread(void *arg)
{
    (void)arg;

    uint8_t           pkt[PKT_BUF];
    WINDIVERT_ADDRESS addr;
    UINT              pkt_len;

    while (g_running) {
        if (!WinDivertRecv(g_handle, pkt, sizeof(pkt), &pkt_len, &addr)) {
            if (!g_running) break;
            continue;
        }

        WINDIVERT_IPHDR   *ip  = NULL;
        WINDIVERT_IPV6HDR *ip6 = NULL;
        WINDIVERT_TCPHDR  *tcp = NULL;
        UINT               payload_len = 0;
        uint8_t           *payload = NULL;

        WinDivertHelperParsePacket(pkt, pkt_len,
            &ip, &ip6, NULL, NULL, NULL, &tcp, NULL,
            (PVOID*)&payload, &payload_len, NULL, NULL);

        /* Только исходящий TCP с payload */
        if (!tcp || !addr.Outbound || payload_len < 5) {
            WinDivertSend(g_handle, pkt, pkt_len, NULL, &addr);
            continue;
        }

        /* TLS ClientHello: record type 0x16 */
        if (payload[0] != 0x16) {
            WinDivertSend(g_handle, pkt, pkt_len, NULL, &addr);
            continue;
        }

        /* Извлекаем SNI */
        char sni_str[256] = {0};
        extract_sni_string(payload, payload_len, sni_str, sizeof(sni_str));

        if (!should_bypass(sni_str)) {
            WinDivertSend(g_handle, pkt, pkt_len, NULL, &addr);
            continue;
        }

        /* Точка разбивки */
        int sni_off = find_sni_offset(payload, payload_len);
        int split_at = 0;

        if (sni_off > 0 && sni_off < (int)payload_len) {
            split_at = sni_off;
        } else if (g_opts.opts.split_pos > 0 &&
                   g_opts.opts.split_pos < (int)payload_len) {
            split_at = g_opts.opts.split_pos;
        } else {
            /* SNI не найден — пропускаем без изменений */
            WinDivertSend(g_handle, pkt, pkt_len, NULL, &addr);
            continue;
        }

        if (split_at <= 0 || split_at >= (int)payload_len) {
            WinDivertSend(g_handle, pkt, pkt_len, NULL, &addr);
            continue;
        }

        /* IPv6: ip == NULL, берём начало буфера */
        WINDIVERT_IPHDR *ip_hdr = ip ? ip : (WINDIVERT_IPHDR *)pkt;

        LOG("WD: bypass [%s] port=%d split@%d SNI@%d disorder=%d fake_ttl=%d",
            sni_str[0] ? sni_str : "?",
            ntohs(tcp->DstPort), split_at, sni_off,
            g_opts.opts.disorder, g_opts.opts.fake_ttl);

        send_desync(g_handle,
                    ip_hdr, tcp,
                    payload, payload_len,
                    (UINT)split_at,
                    &addr,
                    g_opts.opts.disorder,
                    g_opts.opts.fake_ttl);
        /* Оригинал НЕ реинжектируем — уже отправили части */
    }

    return 0;
}

/* ------------------------------------------------------------------ */
/* Публичный API                                                        */
/* ------------------------------------------------------------------ */

int wd_engine_start(const wd_engine_opts_t *opts)
{
    if (g_running) return 0;

    g_opts = *opts;

    const char *filter = opts->filter[0]
        ? opts->filter
        : "outbound and tcp and tcp.PayloadLength > 0 and "
          "(tcp.DstPort == 443 or tcp.DstPort == 80 or tcp.DstPort == 8443)";

    g_handle = WinDivertOpen(filter, WINDIVERT_LAYER_NETWORK, 0, 0);
    if (g_handle == INVALID_HANDLE_VALUE) {
        LOG("WinDivertOpen failed: %lu (запусти от администратора)", GetLastError());
        return -1;
    }

    WinDivertSetParam(g_handle, WINDIVERT_PARAM_QUEUE_LENGTH, 16384);
    WinDivertSetParam(g_handle, WINDIVERT_PARAM_QUEUE_TIME,   2000);
    WinDivertSetParam(g_handle, WINDIVERT_PARAM_QUEUE_SIZE,   33554432);

    g_running = 1;

    g_thread = NULL;
    for (int i = 0; i < NUM_THREADS; i++) {
        HANDLE t = (HANDLE)_beginthreadex(NULL, 0, engine_thread, NULL, 0, NULL);
        if (i == 0) g_thread = t;
    }

    if (!g_thread) {
        g_running = 0;
        WinDivertClose(g_handle);
        g_handle = INVALID_HANDLE_VALUE;
        return -1;
    }

    /*
     * Дропаем входящие RST от провайдера.
     * Провайдер шлёт RST после DPI-анализа — дропаем их.
     */
    g_rst_handle = WinDivertOpen(
        "inbound and tcp and tcp.Rst and "
        "(tcp.SrcPort == 443 or tcp.SrcPort == 80 or tcp.SrcPort == 8443)",
        WINDIVERT_LAYER_NETWORK, 1, WINDIVERT_FLAG_DROP);
    if (g_rst_handle != INVALID_HANDLE_VALUE)
        LOG("RST drop filter active");
    else
        LOG("RST drop filter failed (non-critical): %lu", GetLastError());

    LOG("WinDivert engine started, %d threads (filter: %s)", NUM_THREADS, filter);
    return 0;
}

void wd_engine_stop(void)
{
    if (!g_running) return;
    g_running = 0;
    if (g_rst_handle != INVALID_HANDLE_VALUE) {
        WinDivertClose(g_rst_handle);
        g_rst_handle = INVALID_HANDLE_VALUE;
    }
    if (g_handle != INVALID_HANDLE_VALUE) {
        WinDivertClose(g_handle);
        g_handle = INVALID_HANDLE_VALUE;
    }
    if (g_thread) {
        WaitForSingleObject(g_thread, 3000);
        CloseHandle(g_thread);
        g_thread = NULL;
    }
    LOG("WinDivert engine stopped");
}

int wd_engine_running(void)
{
    return g_running;
}

#endif /* _WIN32 */
