#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "bypass.h"

#ifdef _WIN32
  #include <winsock2.h>
  #include <ws2tcpip.h>
  #include <windows.h>
#else
  #include <netinet/ip.h>
  #include <netinet/tcp.h>
  #include <time.h>
#endif

/* ── SNI parser ───────────────────────────────────────────────────────────── */

int find_sni_offset(const uint8_t *buf, size_t len) {
    if (len < 5) return -1;
    if (buf[0] != 0x16 || buf[1] != 0x03) return -1;

    size_t pos = 5;
    if (pos + 4 > len || buf[pos] != 0x01) return -1;
    pos += 4;

    if (pos + 34 > len) return -1;
    pos += 34; /* ProtocolVersion + Random */

    if (pos + 1 > len) return -1;
    pos += 1 + buf[pos]; /* SessionID */

    if (pos + 2 > len) return -1;
    uint16_t cs_len = (uint16_t)((buf[pos] << 8) | buf[pos+1]);
    pos += 2 + cs_len;

    if (pos + 1 > len) return -1;
    pos += 1 + buf[pos]; /* CompressionMethods */

    if (pos + 2 > len) return -1;
    uint16_t ext_total = (uint16_t)((buf[pos] << 8) | buf[pos+1]);
    pos += 2;

    size_t ext_end = pos + ext_total;
    if (ext_end > len) ext_end = len;

    while (pos + 4 <= ext_end) {
        uint16_t ext_type = (uint16_t)((buf[pos] << 8) | buf[pos+1]);
        uint16_t ext_len  = (uint16_t)((buf[pos+2] << 8) | buf[pos+3]);
        pos += 4;
        if (ext_type == 0x0000) { /* server_name */
            if (pos + 5 > ext_end) return -1;
            if (buf[pos+2] != 0x00) return -1;
            uint16_t name_len = (uint16_t)((buf[pos+3] << 8) | buf[pos+4]);
            if (name_len == 0 || pos + 5 + name_len > ext_end) return -1;
            return (int)(pos + 5);
        }
        pos += ext_len;
    }
    return -1;
}

/* ── helpers ──────────────────────────────────────────────────────────────── */

static void delay_ms(int ms) {
#ifdef _WIN32
    Sleep((DWORD)ms);
#else
    struct timespec ts = {0, (long)ms * 1000000L};
    nanosleep(&ts, NULL);
#endif
}

static int send_all_raw(sock_t s, const uint8_t *buf, size_t len) {
    size_t sent = 0;
    while (sent < len) {
        int n = send(s, (const char*)(buf + sent), (int)(len - sent), 0);
        if (n <= 0) return -1;
        sent += n;
    }
    return 0;
}

static int send_segment(sock_t s, const uint8_t *buf, size_t len) {
    int r = send_all_raw(s, buf, len);
    delay_ms(1);
    return r;
}

static void send_oob(sock_t s) {
    uint8_t b = 0x00;
    send(s, (const char*)&b, 1, MSG_OOB);
    delay_ms(1);
}

/*
 * Build a fake TLS record with junk payload of the same length.
 * Uses TTL=1 so it dies before reaching the server but fools DPI.
 * Only works on Linux/Android where we can set IP_TTL per-socket.
 */
static void send_fake_record(sock_t s, const uint8_t *buf, size_t len) {
#ifndef _WIN32
    int old_ttl = 64;
    socklen_t optlen = sizeof(old_ttl);
    getsockopt(s, IPPROTO_IP, IP_TTL, &old_ttl, &optlen);

    int fake_ttl = 1;
    setsockopt(s, IPPROTO_IP, IP_TTL, &fake_ttl, sizeof(fake_ttl));

    /* Junk: same length, first byte 0x00 (not TLS) so DPI is confused */
    uint8_t *junk = (uint8_t *)malloc(len);
    if (junk) {
        memset(junk, 0xAA, len);
        junk[0] = 0x00;
        send_all_raw(s, junk, len);
        free(junk);
    }

    setsockopt(s, IPPROTO_IP, IP_TTL, &old_ttl, sizeof(old_ttl));
    delay_ms(1);
#else
    (void)s; (void)buf; (void)len;
#endif
}

static int send_disorder(sock_t s, const uint8_t *buf, size_t split,
                          size_t len, int use_oob) {
#ifdef _WIN32
    if (use_oob) send_oob(s);
    if (send_segment(s, buf, split) < 0) return -1;
    if (use_oob) send_oob(s);
    if (send_all_raw(s, buf + split, len - split) < 0) return -1;
#else
    int old_ttl = 64;
    socklen_t optlen = sizeof(old_ttl);
    getsockopt(s, IPPROTO_IP, IP_TTL, &old_ttl, &optlen);

    /* Send seg2 first (server buffers it) */
    if (send_segment(s, buf + split, len - split) < 0) return -1;

    /* Send seg1 with TTL=1 — DPI sees it, server drops it */
    int fake_ttl = 1;
    setsockopt(s, IPPROTO_IP, IP_TTL, &fake_ttl, sizeof(fake_ttl));
    send_all_raw(s, buf, split);
    delay_ms(1);

    /* Send real seg1 */
    setsockopt(s, IPPROTO_IP, IP_TTL, &old_ttl, sizeof(old_ttl));
    if (send_segment(s, buf, split) < 0) return -1;
#endif
    return 0;
}

/* ── main bypass logic ────────────────────────────────────────────────────── */

int bypass_send(sock_t s, const uint8_t *buf, size_t len, const bypass_opts_t *opts) {
    /* Not TLS ClientHello — pass through */
    if (len < 5 || buf[0] != 0x16) {
        return (int)send_all(s, buf, len);
    }

    int sni_off = find_sni_offset(buf, len);
    int split   = 0;

    if (sni_off > 0 && sni_off < (int)len) {
        if (opts->tlsrec_split) {
            /*
             * Split INSIDE the SNI string — most effective against modern DPI.
             * Cut the SNI name in half: DPI can't reconstruct the hostname.
             *
             * Layout around SNI:
             *   [sni_off - 5] = list_length(2)
             *   [sni_off - 3] = entry_type(1)
             *   [sni_off - 2] = name_length(2)
             *   [sni_off]     = first byte of SNI string
             *
             * We split at sni_off + sni_len/2 (middle of the hostname).
             */
            uint16_t sni_len = (uint16_t)((buf[sni_off - 2] << 8) | buf[sni_off - 1]);
            int mid = sni_off + (sni_len / 2);
            if (mid > 0 && mid < (int)len)
                split = mid;
            else
                split = sni_off; /* fallback: split before SNI */
        } else if (opts->split_pos > 0 && opts->split_pos < (int)len) {
            split = opts->split_pos;
        } else {
            /* Default: split right before SNI extension value */
            split = sni_off;
        }
    } else if (opts->split_pos > 0 && opts->split_pos < (int)len) {
        split = opts->split_pos;
    }

    if (split <= 0) {
        return (int)send_all(s, buf, len);
    }

    if (opts->disorder) {
        if (send_disorder(s, buf, (size_t)split, len, opts->oob) < 0) return -1;
        return (int)len;
    }

    /*
     * Standard split with optional fake record injection:
     *   1. [optional] fake record (TTL=1, junk) — confuses DPI state machine
     *   2. seg1 [0..split)
     *   3. [optional] OOB byte
     *   4. seg2 [split..end)
     */
    if (opts->fake_ttl > 0) {
        send_fake_record(s, buf, (size_t)split);
    }

    if (send_segment(s, buf, (size_t)split) < 0) return -1;
    if (opts->oob) send_oob(s);
    if (send_all_raw(s, buf + split, len - (size_t)split) < 0) return -1;

    return (int)len;
}
