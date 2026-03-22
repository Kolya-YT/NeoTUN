#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "socks5.h"

#ifdef _WIN32
  #include <winsock2.h>
  #include <ws2tcpip.h>
#else
  #include <sys/select.h>
  #include <netdb.h>
#endif

/* ---- HTTP CONNECT ---- */
static int http_connect_handshake(sock_t client, socks5_target_t *target,
                                   uint8_t *leftover, int *leftover_len) {
    /* Читаем HTTP запрос побайтово до \r\n\r\n */
    char buf[2048];
    int len = 0;
    while (len < (int)sizeof(buf) - 1) {
        int n = recv(client, buf + len, 1, 0);
        if (n <= 0) return -1;
        len++;
        if (len >= 4 &&
            buf[len-4]=='\r' && buf[len-3]=='\n' &&
            buf[len-2]=='\r' && buf[len-1]=='\n') break;
    }
    buf[len] = '\0';

    /* Парсим: CONNECT host:port HTTP/1.x */
    if (strncmp(buf, "CONNECT ", 8) != 0) return -1;

    char *host_start = buf + 8;
    char *space = strchr(host_start, ' ');
    if (!space) return -1;
    *space = '\0';

    /* Разделяем host:port */
    char *colon = strrchr(host_start, ':');
    if (colon) {
        *colon = '\0';
        target->port = (uint16_t)atoi(colon + 1);
    } else {
        target->port = 443;
    }
    strncpy(target->host, host_start, sizeof(target->host) - 1);

    *leftover_len = 0;
    return 0;
}

static void http_connect_reply_ok(sock_t client) {
    const char *resp = "HTTP/1.1 200 Connection established\r\n\r\n";
    send(client, resp, (int)strlen(resp), 0);
}

static void http_connect_reply_err(sock_t client) {
    const char *resp = "HTTP/1.1 502 Bad Gateway\r\n\r\n";
    send(client, resp, (int)strlen(resp), 0);
}

/* ---- SOCKS5 ---- */
static int socks5_handshake(sock_t client, socks5_target_t *target) {
    uint8_t buf[512];

    if (recv(client, (char*)buf, 2, MSG_WAITALL) != 2) return -1;
    if (buf[0] != SOCKS5_VERSION) return -1;

    uint8_t nmethods = buf[1];
    if (nmethods > 0 && recv(client, (char*)buf, nmethods, MSG_WAITALL) != nmethods) return -1;

    uint8_t resp[2] = {SOCKS5_VERSION, 0x00};
    if (send(client, (char*)resp, 2, 0) != 2) return -1;

    if (recv(client, (char*)buf, 4, MSG_WAITALL) != 4) return -1;
    if (buf[0] != SOCKS5_VERSION || buf[1] != SOCKS5_CMD_CONNECT) return -1;

    uint8_t atyp = buf[3];
    memset(target, 0, sizeof(*target));

    if (atyp == SOCKS5_ATYP_IPV4) {
        uint8_t ip[4];
        if (recv(client, (char*)ip, 4, MSG_WAITALL) != 4) return -1;
        snprintf(target->host, sizeof(target->host),
                 "%d.%d.%d.%d", ip[0], ip[1], ip[2], ip[3]);
    } else if (atyp == SOCKS5_ATYP_DOMAIN) {
        uint8_t dlen;
        if (recv(client, (char*)&dlen, 1, MSG_WAITALL) != 1) return -1;
        if (recv(client, (char*)target->host, dlen, MSG_WAITALL) != dlen) return -1;
        target->host[dlen] = '\0';
    } else if (atyp == SOCKS5_ATYP_IPV6) {
        uint8_t ip6[16];
        if (recv(client, (char*)ip6, 16, MSG_WAITALL) != 16) return -1;
        snprintf(target->host, sizeof(target->host),
                 "%02x%02x:%02x%02x:%02x%02x:%02x%02x:"
                 "%02x%02x:%02x%02x:%02x%02x:%02x%02x",
                 ip6[0],ip6[1],ip6[2],ip6[3],ip6[4],ip6[5],ip6[6],ip6[7],
                 ip6[8],ip6[9],ip6[10],ip6[11],ip6[12],ip6[13],ip6[14],ip6[15]);
    } else {
        return -1;
    }

    uint8_t port_buf[2];
    if (recv(client, (char*)port_buf, 2, MSG_WAITALL) != 2) return -1;
    target->port = (uint16_t)((port_buf[0] << 8) | port_buf[1]);
    return 0;
}

static void send_socks5_reply(sock_t client, uint8_t status) {
    uint8_t reply[10] = {
        SOCKS5_VERSION, status, 0x00, SOCKS5_ATYP_IPV4,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    };
    send(client, (char*)reply, 10, 0);
}

/* ---- Upstream SOCKS5 ---- */
/*
 * Подключиться к upstream SOCKS5 прокси и попросить его сделать
 * CONNECT к target_host:target_port. Возвращает готовый сокет или SOCK_INVALID.
 */
static sock_t connect_via_upstream(const upstream_t *up,
                                    const char *target_host, uint16_t target_port) {
    struct addrinfo hints, *res = NULL;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family   = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    char port_str[8];
    snprintf(port_str, sizeof(port_str), "%d", up->port);

    if (getaddrinfo(up->host, port_str, &hints, &res) != 0) {
        LOG("Upstream DNS failed: %s", up->host);
        return SOCK_INVALID;
    }

    sock_t s = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
    if (s == SOCK_INVALID) { freeaddrinfo(res); return SOCK_INVALID; }
    set_nodelay(s);

    if (connect(s, res->ai_addr, (int)res->ai_addrlen) != 0) {
        LOG("Upstream connect failed: %s:%d", up->host, up->port);
        freeaddrinfo(res);
        sock_close(s);
        return SOCK_INVALID;
    }
    freeaddrinfo(res);

    /* SOCKS5 greeting: no auth */
    uint8_t greeting[3] = {0x05, 0x01, 0x00};
    if (send(s, (char*)greeting, 3, 0) != 3) { sock_close(s); return SOCK_INVALID; }
    uint8_t srv_choice[2];
    if (recv(s, (char*)srv_choice, 2, MSG_WAITALL) != 2 || srv_choice[1] != 0x00) {
        LOG("Upstream auth failed");
        sock_close(s);
        return SOCK_INVALID;
    }

    /* SOCKS5 CONNECT request */
    uint8_t req[4 + 1 + 255 + 2];
    req[0] = 0x05; req[1] = 0x01; req[2] = 0x00; req[3] = 0x03;
    size_t hlen = strlen(target_host);
    if (hlen > 255) hlen = 255;
    req[4] = (uint8_t)hlen;
    memcpy(req + 5, target_host, hlen);
    req[5 + hlen]     = (uint8_t)(target_port >> 8);
    req[5 + hlen + 1] = (uint8_t)(target_port & 0xff);
    int req_len = (int)(5 + hlen + 2);

    if (send(s, (char*)req, req_len, 0) != req_len) { sock_close(s); return SOCK_INVALID; }

    /* Ответ: минимум 10 байт */
    uint8_t resp[10];
    if (recv(s, (char*)resp, 10, MSG_WAITALL) != 10 || resp[1] != 0x00) {
        LOG("Upstream CONNECT refused: %s:%d (code=%d)", target_host, target_port,
            resp[1]);
        sock_close(s);
        return SOCK_INVALID;
    }

    return s;
}

/* ---- Tunnel ---- */
void proxy_tunnel(sock_t client, sock_t remote, const bypass_opts_t *opts) {
    uint8_t buf[16384];
    int first_from_client = 1;

    /* Buffer for assembling the first TLS ClientHello */
    uint8_t hello_buf[16384];
    int hello_len = 0;

    for (;;) {
        fd_set rd;
        FD_ZERO(&rd);
        FD_SET(client, &rd);
        FD_SET(remote, &rd);

        int maxfd = (int)(client > remote ? client : remote) + 1;
        struct timeval tv = {120, 0};
        int ret = select(maxfd, &rd, NULL, NULL, &tv);
        if (ret <= 0) break;

        if (FD_ISSET(client, &rd)) {
            int n = recv(client, (char*)buf, sizeof(buf), 0);
            if (n <= 0) break;

            if (first_from_client) {
                /* Accumulate until we have a full TLS record or non-TLS data */
                if (hello_len + n > (int)sizeof(hello_buf))
                    n = (int)sizeof(hello_buf) - hello_len;
                memcpy(hello_buf + hello_len, buf, n);
                hello_len += n;

                /* Check if it's a TLS ClientHello and we have the full record */
                int is_tls = (hello_len >= 5 &&
                              hello_buf[0] == 0x16 &&
                              hello_buf[1] == 0x03);
                int tls_record_len = is_tls
                    ? (5 + ((hello_buf[3] << 8) | hello_buf[4]))
                    : 0;

                /* Send once we have the full record, or it's not TLS */
                if (!is_tls || hello_len >= tls_record_len) {
                    first_from_client = 0;
                    if (bypass_send(remote, hello_buf, (size_t)hello_len, opts) < 0) break;
                }
                /* else: keep accumulating */
            } else {
                if (send_all(remote, buf, (size_t)n) < 0) break;
            }
        }

        if (FD_ISSET(remote, &rd)) {
            int n = recv(remote, (char*)buf, sizeof(buf), 0);
            if (n <= 0) break;
            if (send_all(client, buf, (size_t)n) < 0) break;
        }
    }
}

/* ---- Общий обработчик ---- */
void handle_client(sock_t client, const bypass_opts_t *opts, const upstream_t *upstream) {
    /* Читаем первый байт чтобы определить протокол */
    uint8_t first;
    if (recv(client, (char*)&first, 1, MSG_WAITALL) != 1) {
        sock_close(client);
        return;
    }

    socks5_target_t target;
    memset(&target, 0, sizeof(target));
    int is_http = 0;

    if (first == SOCKS5_VERSION) {
        /* SOCKS5 */
        uint8_t nmethods_buf;
        if (recv(client, (char*)&nmethods_buf, 1, MSG_WAITALL) != 1) {
            sock_close(client); return;
        }
        uint8_t methods[255];
        if (nmethods_buf > 0 && recv(client, (char*)methods, nmethods_buf, MSG_WAITALL) != nmethods_buf) {
            sock_close(client); return;
        }
        uint8_t resp[2] = {SOCKS5_VERSION, 0x00};
        send(client, (char*)resp, 2, 0);

        uint8_t req[4];
        if (recv(client, (char*)req, 4, MSG_WAITALL) != 4 ||
            req[0] != SOCKS5_VERSION || req[1] != SOCKS5_CMD_CONNECT) {
            sock_close(client); return;
        }
        uint8_t atyp = req[3];
        if (atyp == SOCKS5_ATYP_IPV4) {
            uint8_t ip[4];
            if (recv(client, (char*)ip, 4, MSG_WAITALL) != 4) { sock_close(client); return; }
            snprintf(target.host, sizeof(target.host), "%d.%d.%d.%d", ip[0],ip[1],ip[2],ip[3]);
        } else if (atyp == SOCKS5_ATYP_DOMAIN) {
            uint8_t dlen;
            if (recv(client, (char*)&dlen, 1, MSG_WAITALL) != 1) { sock_close(client); return; }
            if (recv(client, (char*)target.host, dlen, MSG_WAITALL) != dlen) { sock_close(client); return; }
            target.host[dlen] = '\0';
        } else if (atyp == SOCKS5_ATYP_IPV6) {
            uint8_t ip6[16];
            if (recv(client, (char*)ip6, 16, MSG_WAITALL) != 16) { sock_close(client); return; }
            snprintf(target.host, sizeof(target.host),
                     "%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x",
                     ip6[0],ip6[1],ip6[2],ip6[3],ip6[4],ip6[5],ip6[6],ip6[7],
                     ip6[8],ip6[9],ip6[10],ip6[11],ip6[12],ip6[13],ip6[14],ip6[15]);
        } else { sock_close(client); return; }
        uint8_t port_buf[2];
        if (recv(client, (char*)port_buf, 2, MSG_WAITALL) != 2) { sock_close(client); return; }
        target.port = (uint16_t)((port_buf[0] << 8) | port_buf[1]);

    } else if (first == 'C') {
        /* HTTP CONNECT */
        is_http = 1;
        char buf[2048];
        buf[0] = (char)first;
        int len = 1;
        while (len < (int)sizeof(buf) - 1) {
            int n = recv(client, buf + len, 1, 0);
            if (n <= 0) { sock_close(client); return; }
            len++;
            if (len >= 4 &&
                buf[len-4]=='\r' && buf[len-3]=='\n' &&
                buf[len-2]=='\r' && buf[len-1]=='\n') break;
        }
        buf[len] = '\0';
        if (strncmp(buf, "CONNECT ", 8) != 0) { sock_close(client); return; }
        char *host_start = buf + 8;
        char *space = strchr(host_start, ' ');
        if (!space) { sock_close(client); return; }
        *space = '\0';
        char *colon = strrchr(host_start, ':');
        if (colon) { *colon = '\0'; target.port = (uint16_t)atoi(colon + 1); }
        else { target.port = 443; }
        strncpy(target.host, host_start, sizeof(target.host) - 1);
    } else {
        LOG("Unknown protocol, first byte=0x%02x", first);
        sock_close(client);
        return;
    }

    LOG("[%s] -> %s:%d", is_http ? "HTTP" : "SOCKS5", target.host, target.port);

    sock_t remote = SOCK_INVALID;

    if (upstream && upstream->host[0]) {
        /* Подключаемся через upstream SOCKS5 */
        remote = connect_via_upstream(upstream, target.host, target.port);
        if (remote == SOCK_INVALID) {
            LOG("Upstream failed for %s:%d", target.host, target.port);
            if (is_http) http_connect_reply_err(client);
            else send_socks5_reply(client, 0x04);
            sock_close(client);
            return;
        }
    } else {
        /* Прямое подключение */
        struct addrinfo hints, *res = NULL;
        memset(&hints, 0, sizeof(hints));
        hints.ai_family   = AF_UNSPEC;
        hints.ai_socktype = SOCK_STREAM;
        char port_str[8];
        snprintf(port_str, sizeof(port_str), "%d", target.port);

        if (getaddrinfo(target.host, port_str, &hints, &res) != 0) {
            LOG("DNS failed: %s", target.host);
            if (is_http) http_connect_reply_err(client);
            else send_socks5_reply(client, 0x04);
            sock_close(client);
            return;
        }

        remote = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
        if (remote == SOCK_INVALID) {
            freeaddrinfo(res);
            if (is_http) http_connect_reply_err(client);
            else send_socks5_reply(client, 0x01);
            sock_close(client);
            return;
        }
        /* Protect from VPN routing loop on Android */
        android_protect_socket((int)remote);
        set_nodelay(remote);

        if (connect(remote, res->ai_addr, (int)res->ai_addrlen) != 0) {
            LOG("Connect failed: %s:%d", target.host, target.port);
            freeaddrinfo(res);
            sock_close(remote);
            if (is_http) http_connect_reply_err(client);
            else send_socks5_reply(client, 0x05);
            sock_close(client);
            return;
        }
        freeaddrinfo(res);
    }

    /* Отвечаем клиенту об успехе */
    if (is_http) http_connect_reply_ok(client);
    else send_socks5_reply(client, 0x00);

    proxy_tunnel(client, remote, opts);

    sock_close(remote);
    sock_close(client);
}
