#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "socks5.h"
#include "bypass.h"
#include "utils.h"

#ifdef _WIN32
  #include <winsock2.h>
  #include <ws2tcpip.h>
  #include <process.h>
  #include "windivert_engine.h"
  typedef HANDLE thread_t;
#else
  #include <pthread.h>
  #include <signal.h>
  typedef pthread_t thread_t;
#endif

typedef struct {
    sock_t client;
    bypass_opts_t opts;
    upstream_t upstream;
} client_ctx_t;

#ifdef _WIN32
static unsigned __stdcall client_thread(void *arg) {
#else
static void* client_thread(void *arg) {
#endif
    client_ctx_t *ctx = (client_ctx_t*)arg;
    handle_client(ctx->client, &ctx->opts, &ctx->upstream);
    free(ctx);
    return 0;
}

static void print_usage(const char *prog) {
    printf("Usage: %s [options]\n"
           "  -i <ip>       Listen IP (default: 127.0.0.1)\n"
           "  -p <port>     Listen port (default: 1080)\n"
           "  -s <pos>      Split position (default: 0 = off)\n"
           "  -d            Disorder mode\n"
           "  -f <ttl>      Fake packet TTL (default: -1 = off)\n"
           "  -t            Split TLS record at SNI\n"
           "  -o            Send OOB byte between split parts\n"
           "  -U <host>     Upstream SOCKS5 proxy host\n"
           "  -P <port>     Upstream SOCKS5 proxy port (default: 1080)\n"
#ifdef _WIN32
           "  -w            WinDivert mode (system-wide, no proxy needed, requires admin)\n"
#endif
           "  -h            Show this help\n",
           prog);
}

int main(int argc, char *argv[]) {
#ifdef _WIN32
    WSADATA wsa;
    WSAStartup(MAKEWORD(2,2), &wsa);
#else
    signal(SIGPIPE, SIG_IGN);
#endif

    const char *listen_ip = "127.0.0.1";
    int listen_port = 1080;

    bypass_opts_t opts = {
        .split_pos   = 0,
        .disorder    = 0,
        .fake_ttl    = -1,
        .tlsrec_split = 0,
        .oob         = 0
    };

    upstream_t upstream;
    memset(&upstream, 0, sizeof(upstream));
    int upstream_port = 1080;
    int windivert_mode = 0;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-i") == 0 && i+1 < argc) {
            listen_ip = argv[++i];
        } else if (strcmp(argv[i], "-p") == 0 && i+1 < argc) {
            listen_port = atoi(argv[++i]);
        } else if (strcmp(argv[i], "-s") == 0 && i+1 < argc) {
            opts.split_pos = atoi(argv[++i]);
        } else if (strcmp(argv[i], "-d") == 0) {
            opts.disorder = 1;
        } else if (strcmp(argv[i], "-f") == 0 && i+1 < argc) {
            opts.fake_ttl = atoi(argv[++i]);
        } else if (strcmp(argv[i], "-t") == 0) {
            opts.tlsrec_split = 1;
        } else if (strcmp(argv[i], "-o") == 0) {
            opts.oob = 1;
        } else if (strcmp(argv[i], "-U") == 0 && i+1 < argc) {
            strncpy(upstream.host, argv[++i], sizeof(upstream.host) - 1);
        } else if (strcmp(argv[i], "-P") == 0 && i+1 < argc) {
            upstream_port = atoi(argv[++i]);
        } else if (strcmp(argv[i], "-w") == 0) {
            windivert_mode = 1;
        } else if (strcmp(argv[i], "-h") == 0) {
            print_usage(argv[0]);
            return 0;
        }
    }
    upstream.port = (uint16_t)upstream_port;

#ifdef _WIN32
    if (windivert_mode) {
        wd_engine_opts_t wd = {0};
        wd.opts = opts;
        /* Фильтр: исходящий TCP:443 с payload (TLS) */
        strncpy(wd.filter,
                "outbound and tcp.DstPort == 443 and tcp.PayloadLength > 0",
                sizeof(wd.filter) - 1);
        printf("NeoTUN - DPI bypass (WinDivert mode, system-wide)\n");
        printf("Options: split=%d disorder=%d fake_ttl=%d tlsrec=%d\n",
               opts.split_pos, opts.disorder, opts.fake_ttl, opts.tlsrec_split);
        if (wd_engine_start(&wd) != 0) {
            fprintf(stderr, "Failed to start WinDivert engine.\n"
                            "Make sure you run as Administrator.\n");
            return 1;
        }
        printf("Running... Press Ctrl+C to stop.\n");
        /* Ждём сигнала завершения */
        while (wd_engine_running()) Sleep(500);
        wd_engine_stop();
        WSACleanup();
        return 0;
    }
#else
    (void)windivert_mode;
#endif

    sock_t server = socket(AF_INET, SOCK_STREAM, 0);
    if (server == SOCK_INVALID) {
        LOG("Failed to create socket");
        return 1;
    }

    int reuse = 1;
    setsockopt(server, SOL_SOCKET, SO_REUSEADDR, (const char*)&reuse, sizeof(reuse));

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port   = htons((uint16_t)listen_port);
    inet_pton(AF_INET, listen_ip, &addr.sin_addr);

    if (bind(server, (struct sockaddr*)&addr, sizeof(addr)) != 0) {
        LOG("Bind failed on %s:%d", listen_ip, listen_port);
        sock_close(server);
        return 1;
    }

    if (listen(server, 128) != 0) {
        LOG("Listen failed");
        sock_close(server);
        return 1;
    }

    printf("DPI Bypass SOCKS5 proxy listening on %s:%d\n", listen_ip, listen_port);
    printf("Options: split=%d disorder=%d fake_ttl=%d tlsrec=%d oob=%d upstream=%s:%d\n",
           opts.split_pos, opts.disorder, opts.fake_ttl, opts.tlsrec_split, opts.oob,
           upstream.host[0] ? upstream.host : "none", upstream.port);

    while (1) {
        struct sockaddr_in client_addr;
        socklen_t client_len = sizeof(client_addr);
        sock_t client = accept(server, (struct sockaddr*)&client_addr, &client_len);
        if (client == SOCK_INVALID) continue;

        set_nodelay(client);

        client_ctx_t *ctx = malloc(sizeof(client_ctx_t));
        if (!ctx) { sock_close(client); continue; }
        ctx->client = client;
        ctx->opts   = opts;
        ctx->upstream = upstream;

#ifdef _WIN32
        _beginthreadex(NULL, 0, client_thread, ctx, 0, NULL);
#else
        pthread_t tid;
        pthread_attr_t attr;
        pthread_attr_init(&attr);
        pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
        pthread_create(&tid, &attr, client_thread, ctx);
        pthread_attr_destroy(&attr);
#endif
    }

#ifdef _WIN32
    WSACleanup();
#endif
    return 0;
}
