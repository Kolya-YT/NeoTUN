#pragma once
#include <stdint.h>

/* Запустить TUN движок. tun_fd — файловый дескриптор TUN интерфейса. */
int tun_engine_start(int tun_fd, int fake_ttl, int disorder);

/* Остановить TUN движок. */
void tun_engine_stop(void);
