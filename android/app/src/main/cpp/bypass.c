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

/* Найти SNI в TLS ClientHello
   Структура: TLS Record (5) -> Handshake (4) -> ClientHello -> extensions -> SNI
   Возвращает смещение начала SNI-строки (после 2 байт длины) или -1 */
int find_sni_offset(const uint8_t *buf, size_t len) {
    if (len < 5) return -1;
    /* TLS Handshake record */
    if (buf[0] != 0x16) return -1;
    /* version: 0x0301..0x0303 */
    if (buf[1] != 0x03) return -1;

    size_t pos = 5; /* пропускаем TLS record header */

    /* Handshake header: type(1) + length(3) */
    if (pos + 4 > len) return -1;
    if (buf[pos] != 0x01) return -1; /* ClientHello */
    pos += 4;

    /* ProtocolVersion(2) + Random(32) = 34 байта */
    if (pos + 34 > len) return -1;
    pos += 34;

    /* SessionID: length(1) + data */
    if (pos + 1 > len) return -1;
    uint8_t sid_len = buf[pos];
    pos += 1 + sid_len;

    /* CipherSuites: length(2) + data */
    if (pos + 2 > len) return -1;
    uint16_t cs_len = (uint16_t)((buf[pos] << 8) | buf[pos+1]);
    pos += 2 + cs_len;

    /* CompressionMethods: length(1) + data */
    if (pos + 1 > len) return -1;
    uint8_t cm_len = buf[pos];
    pos += 1 + cm_len;

    /* Extensions total length(2) */
    if (pos + 2 > len) return -1;
    uint16_t ext_total = (uint16_t)((buf[pos] << 8) | buf[pos+1]);
    pos += 2;

    size_t ext_end = pos + ext_total;
    if (ext_end > len) ext_end = len; /* фрагментированный пакет */

    /* Перебираем extensions */
    while (pos + 4 <= ext_end) {
        uint16_t ext_type = (uint16_t)((buf[pos] << 8) | buf[pos+1]);
        uint16_t ext_len  = (uint16_t)((buf[pos+2] << 8) | buf[pos+3]);
        pos += 4;

        if (ext_type == 0x0000) { /* server_name */
            /* SNI extension:
               list_length(2) + entry_type(1) + name_length(2) + name */
            if (pos + 5 > ext_end) return -1;
            /* pos+2 = entry_type (0x00 = host_name) */
            /* pos+3..4 = name length */
            /* pos+5 = start of SNI string */
            if (buf[pos+2] != 0x00) return -1; /* не host_name */
            uint16_t name_len = (uint16_t)((buf[pos+3] << 8) | buf[pos+4]);
            if (name_len == 0 || pos + 5 + name_len > ext_end) return -1;
            return (int)(pos + 5); /* смещение начала SNI строки */
        }
        pos += ext_len;
    }
    return -1;
}

/* Задержка 1мс между сегментами */
static void delay_1ms(void) {
#ifdef _WIN32
    Sleep(1);
#else
    struct timespec ts = {0, 1000000};
    nanosleep(&ts, NULL);
#endif
}

/* Отправить один сегмент */
static int send_segment(sock_t s, const uint8_t *buf, size_t len) {
    size_t sent = 0;
    while (sent < len) {
        int n = send(s, (const char*)(buf + sent), (int)(len - sent), 0);
        if (n <= 0) return -1;
        sent += n;
    }
    delay_1ms();
    return 0;
}

/* Отправить OOB (urgent) байт между сегментами — сбивает DPI-стейт машину */
static void send_oob(sock_t s) {
    uint8_t oob_byte = 0x00;
    send(s, (const char*)&oob_byte, 1, MSG_OOB);
    delay_1ms();
}


/*
 * Disorder: отправляем второй сегмент раньше первого.
 * Делается через временное уменьшение TTL первого сегмента —
 * он дойдёт до DPI но не дойдёт до сервера (умрёт по TTL),
 * затем отправляем второй сегмент, потом первый с нормальным TTL.
 * На Windows TTL на TCP сокете менять нельзя без raw sockets,
 * поэтому используем альтернативу: отправляем части с задержкой
 * в обратном порядке через два отдельных соединения невозможно,
 * поэтому disorder на Windows эмулируется через OOB + split.
 */
static int send_disorder(sock_t s, const uint8_t *buf, size_t split,
                          size_t len, int use_oob) {
#ifdef _WIN32
    /* Windows: disorder через OOB перед первым сегментом */
    if (use_oob) send_oob(s);
    if (send_segment(s, buf, split) < 0) return -1;
    if (use_oob) send_oob(s);
    if (send_all(s, buf + split, len - split) < 0) return -1;
#else
    /* Linux: настоящий disorder через TTL=1 для первого сегмента */
    int old_ttl = 64;
    socklen_t optlen = sizeof(old_ttl);
    getsockopt(s, IPPROTO_IP, IP_TTL, &old_ttl, &optlen);

    /* Отправляем второй сегмент первым */
    if (send_segment(s, buf + split, len - split) < 0) return -1;

    /* Отправляем первый сегмент с TTL=1 (умрёт на первом хопе) */
    int fake_ttl = 1;
    setsockopt(s, IPPROTO_IP, IP_TTL, &fake_ttl, sizeof(fake_ttl));
    send(s, (const char*)buf, (int)split, 0);
    delay_1ms();

    /* Отправляем первый сегмент с нормальным TTL */
    setsockopt(s, IPPROTO_IP, IP_TTL, &old_ttl, sizeof(old_ttl));
    if (send_segment(s, buf, split) < 0) return -1;
#endif
    return 0;
}

int bypass_send(sock_t s, const uint8_t *buf, size_t len, const bypass_opts_t *opts) {
    /* Не TLS ClientHello — отправляем как есть */
    if (len < 5 || buf[0] != 0x16) {
        return (int)send_all(s, buf, len);
    }

    /* Определяем точку разбивки */
    int sni = find_sni_offset(buf, len);
    int split = 0;

    if (opts->tlsrec_split && sni > 0 && sni < (int)len) {
        /* Разбиваем прямо по SNI */
        split = sni;
    } else if (opts->split_pos > 0 && opts->split_pos < (int)len) {
        split = opts->split_pos;
    }

    if (split <= 0) {
        /* Нет разбивки — просто отправляем */
        return (int)send_all(s, buf, len);
    }

    if (opts->disorder) {
        /* Disorder: части в обратном порядке */
        if (send_disorder(s, buf, (size_t)split, len, opts->oob) < 0) return -1;
        return (int)len;
    }

    if (opts->tlsrec_split && sni > 0) {
        /*
         * Три части вокруг SNI: [0..sni-1] | [sni] | [sni+1..end]
         * Если включён OOB — вставляем urgent байт между частями
         */
        if (send_segment(s, buf, (size_t)sni) < 0) return -1;
        if (opts->oob) send_oob(s);
        if (send_segment(s, buf + sni, 1) < 0) return -1;
        if (opts->oob) send_oob(s);
        if (send_all(s, buf + sni + 1, len - (size_t)sni - 1) < 0) return -1;
        return (int)len;
    }

    /* Простой split */
    if (send_segment(s, buf, (size_t)split) < 0) return -1;
    if (opts->oob) send_oob(s);
    if (send_all(s, buf + split, len - (size_t)split) < 0) return -1;
    return (int)len;
}
