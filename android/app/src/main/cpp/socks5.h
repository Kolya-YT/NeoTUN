#pragma once
#include "utils.h"
#include "bypass.h"

#define SOCKS5_VERSION  0x05
#define SOCKS5_CMD_CONNECT 0x01
#define SOCKS5_ATYP_IPV4   0x01
#define SOCKS5_ATYP_DOMAIN 0x03
#define SOCKS5_ATYP_IPV6   0x04

typedef struct {
    char host[256];
    uint16_t port;
} socks5_target_t;

/* Upstream SOCKS5 прокси (если host[0] == 0 — не используется) */
typedef struct {
    char host[256];
    uint16_t port;
} upstream_t;

/* Проксировать трафик между client и remote с bypass */
void proxy_tunnel(sock_t client, sock_t remote, const bypass_opts_t *opts);

/* Обработать одно клиентское подключение */
void handle_client(sock_t client, const bypass_opts_t *opts, const upstream_t *upstream);

/* Platform hook: protect socket from VPN routing loop (Android only) */
#ifdef ANDROID_APP
void android_protect_socket(int fd);
#else
static inline void android_protect_socket(int fd) { (void)fd; }
#endif
