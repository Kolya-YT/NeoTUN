#pragma once
#include <stdint.h>
#include <stddef.h>

#ifdef _WIN32
  #include <winsock2.h>
  #include <ws2tcpip.h>
  typedef SOCKET sock_t;
  #define SOCK_INVALID INVALID_SOCKET
  #define sock_close closesocket
  #define sock_errno WSAGetLastError()
#else
  #include <sys/socket.h>
  #include <netinet/in.h>
  #include <arpa/inet.h>
  #include <unistd.h>
  #include <errno.h>
  typedef int sock_t;
  #define SOCK_INVALID (-1)
  #define sock_close close
  #define sock_errno errno
#endif

#define LOG(fmt, ...) fprintf(stderr, "[dpibypass] " fmt "\n", ##__VA_ARGS__)

int set_nonblocking(sock_t s);
int set_nodelay(sock_t s);
ssize_t send_all(sock_t s, const uint8_t *buf, size_t len);
ssize_t recv_all(sock_t s, uint8_t *buf, size_t len);
