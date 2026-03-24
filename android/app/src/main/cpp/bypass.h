#pragma once
#include <stdint.h>
#include <stddef.h>
#include "utils.h"

/* Настройки обхода DPI */
typedef struct {
    int split_pos;      /* позиция разбивки пакета (0 = выкл) */
    int disorder;       /* отправлять части в обратном порядке */
    int fake_ttl;       /* TTL для fake-пакета (-1 = выкл) */
    int tlsrec_split;   /* разбивать TLS record (1 = вкл) */
    int oob;            /* out-of-band байт */
    int http_split;     /* разбивать HTTP Host-заголовок */
    int sni_chunks;     /* количество частей для SNI host при TLS split */
} bypass_opts_t;

/* Найти позицию SNI в TLS ClientHello, вернуть смещение или -1 */
int find_sni_offset(const uint8_t *buf, size_t len);

/* Отправить данные с применением bypass-техник */
int bypass_send(sock_t s, const uint8_t *buf, size_t len, const bypass_opts_t *opts);
