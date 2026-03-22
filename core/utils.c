#include <stdio.h>
#include <string.h>
#include "utils.h"

#ifdef _WIN32
  #include <winsock2.h>
#else
  #include <fcntl.h>
  #include <netinet/tcp.h>
#endif

int set_nonblocking(sock_t s) {
#ifdef _WIN32
    u_long mode = 1;
    return ioctlsocket(s, FIONBIO, &mode) == 0 ? 0 : -1;
#else
    int flags = fcntl(s, F_GETFL, 0);
    if (flags < 0) return -1;
    return fcntl(s, F_SETFL, flags | O_NONBLOCK);
#endif
}

int set_nodelay(sock_t s) {
    int val = 1;
    return setsockopt(s, IPPROTO_TCP, TCP_NODELAY, (const char*)&val, sizeof(val));
}

ssize_t send_all(sock_t s, const uint8_t *buf, size_t len) {
    size_t sent = 0;
    while (sent < len) {
        int n = send(s, (const char*)(buf + sent), (int)(len - sent), 0);
        if (n <= 0) return -1;
        sent += n;
    }
    return (ssize_t)sent;
}

ssize_t recv_all(sock_t s, uint8_t *buf, size_t len) {
    size_t got = 0;
    while (got < len) {
        int n = recv(s, (char*)(buf + got), (int)(len - got), 0);
        if (n <= 0) return -1;
        got += n;
    }
    return (ssize_t)got;
}
