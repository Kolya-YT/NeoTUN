#pragma once
#ifdef _WIN32

#include <stdint.h>
#include "bypass.h"

/*
 * WinDivert-движок — системный перехват пакетов без SOCKS5.
 * Работает прозрачно для всех приложений (браузер, приложения и т.д.)
 * Требует запуска от администратора.
 */

typedef struct {
    bypass_opts_t   opts;
    /* Фильтр WinDivert: по умолчанию только исходящий TCP на порт 443 */
    char            filter[512];
    /* 1 = только домены из blacklist, 0 = все TCP:443 */
    int             use_blacklist;
    const char    **blacklist;   /* NULL-terminated массив доменов */
    int             blacklist_n;
} wd_engine_opts_t;

/* Запустить движок в фоновом потоке. Возвращает 0 при успехе. */
int  wd_engine_start(const wd_engine_opts_t *opts);

/* Остановить движок. */
void wd_engine_stop(void);

/* Проверить запущен ли движок. */
int  wd_engine_running(void);

#endif /* _WIN32 */
