#pragma once
#include <stdint.h>
#include <stddef.h>

/* Найти смещение SNI в TLS ClientHello. Возвращает -1 если не найдено. */
int find_sni_offset(const uint8_t *buf, size_t len);

/* Проверить нужно ли применять bypass к данному SNI */
int should_bypass(const char *sni);
