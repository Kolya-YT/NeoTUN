#include "bypass.h"
#include <string.h>

int find_sni_offset(const uint8_t *buf, size_t len) {
    if (len < 5) return -1;
    if (buf[0] != 0x16 || buf[1] != 0x03) return -1;

    size_t pos = 5;
    if (pos + 4 > len) return -1;
    if (buf[pos] != 0x01) return -1; /* ClientHello */
    pos += 4;

    if (pos + 34 > len) return -1;
    pos += 34; /* version + random */

    if (pos + 1 > len) return -1;
    pos += 1 + buf[pos]; /* session id */

    if (pos + 2 > len) return -1;
    uint16_t cs_len = (uint16_t)((buf[pos] << 8) | buf[pos+1]);
    pos += 2 + cs_len;

    if (pos + 1 > len) return -1;
    pos += 1 + buf[pos]; /* compression */

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

/* Домены которые не трогаем */
static const char *NO_TOUCH[] = {
    "discord.com", "discordapp.com", "discordapp.net",
    "discord.gg", "discord.media", NULL
};

int should_bypass(const char *sni) {
    if (!sni || !sni[0]) return 1;
    size_t sni_len = strlen(sni);
    for (int i = 0; NO_TOUCH[i]; i++) {
        size_t suf_len = strlen(NO_TOUCH[i]);
        if (sni_len >= suf_len) {
            const char *tail = sni + sni_len - suf_len;
            if (strcmp(tail, NO_TOUCH[i]) == 0 &&
                (tail == sni || *(tail-1) == '.'))
                return 0;
        }
    }
    return 1;
}
