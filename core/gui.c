#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <shlobj.h>
#include <commctrl.h>
#include <winsock2.h>
#include <ws2tcpip.h>
#include <stdio.h>
#include <string.h>
#include "windivert_engine.h"
#include "gui.h"

#pragma comment(lib, "comctl32.lib")

/* ── ID элементов ── */
#define ID_BTN_START   101
#define ID_BTN_STOP    102
#define ID_BTN_CHECK   103
#define ID_LOG         104
#define ID_STATUS_ICON 105
#define ID_STATUS_TEXT 106
#define ID_TIMER_CHECK 1

/* ── Цвета ── */
#define CLR_GREEN  RGB(39,174,96)
#define CLR_RED    RGB(192,57,43)
#define CLR_GRAY   RGB(150,150,150)
#define CLR_BG     RGB(30,30,46)
#define CLR_PANEL  RGB(40,40,58)
#define CLR_TEXT   RGB(220,220,220)

static HWND g_hwnd;
static HWND g_btnStart, g_btnStop, g_btnCheck;
static HWND g_log, g_statusText, g_statusDot;
static HFONT g_fontUI, g_fontMono, g_fontBig;
static COLORREF g_dotColor = 0;
static BOOL g_running = FALSE;

/* ── Сервисы для проверки ── */
typedef struct { const char *name; const char *host; } Service;
static Service SERVICES[] = {
    {"YouTube",   "www.youtube.com"},
    {"Discord",   "discord.com"},
    {"Speedtest", "www.speedtest.net"},
};
#define N_SERVICES 3
static HWND g_svcDot[N_SERVICES];
static HWND g_svcLbl[N_SERVICES];
static COLORREF g_svcColor[N_SERVICES];

/* ── Лог ── */
static void log_append(const char *text) {
    int len = GetWindowTextLengthA(g_log);
    SendMessageA(g_log, EM_SETSEL, len, len);
    SendMessageA(g_log, EM_REPLACESEL, FALSE, (LPARAM)text);
    SendMessageA(g_log, EM_REPLACESEL, FALSE, (LPARAM)"\r\n");
    SendMessageA(g_log, EM_SCROLLCARET, 0, 0);
}

static void log_fmt(const char *fmt, ...) {
    char buf[512];
    va_list ap; va_start(ap, fmt); vsnprintf(buf, sizeof(buf), fmt, ap); va_end(ap);
    log_append(buf);
}

/* ── Проверка сервиса (поток) ── */
typedef struct { int idx; char host[128]; } CheckCtx;

static DWORD WINAPI check_thread(LPVOID param) {
    CheckCtx *ctx = (CheckCtx *)param;
    BOOL ok = FALSE;

    /* TCP connect на порт 443 */
    WSADATA wsa; WSAStartup(MAKEWORD(2,2), &wsa);
    struct addrinfo hints = {0}, *res = NULL;
    hints.ai_family   = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    if (getaddrinfo(ctx->host, "443", &hints, &res) == 0 && res) {
        SOCKET s = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
        if (s != INVALID_SOCKET) {
            /* Таймаут 4 сек */
            DWORD tv = 4000;
            setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, (char*)&tv, sizeof(tv));
            setsockopt(s, SOL_SOCKET, SO_SNDTIMEO, (char*)&tv, sizeof(tv));
            if (connect(s, res->ai_addr, (int)res->ai_addrlen) == 0)
                ok = TRUE;
            closesocket(s);
        }
        freeaddrinfo(res);
    }

    g_svcColor[ctx->idx] = ok ? CLR_GREEN : CLR_RED;
    InvalidateRect(g_svcDot[ctx->idx], NULL, TRUE);
    log_fmt("  %s %s", ok ? "✓" : "✗", ctx->host);
    free(ctx);
    return 0;
}

static void do_check(void) {
    log_append("Проверяю...");
    EnableWindow(g_btnCheck, FALSE);
    for (int i = 0; i < N_SERVICES; i++) {
        g_svcColor[i] = CLR_GRAY;
        InvalidateRect(g_svcDot[i], NULL, TRUE);
        CheckCtx *ctx = malloc(sizeof(CheckCtx));
        ctx->idx = i;
        strncpy(ctx->host, SERVICES[i].host, sizeof(ctx->host)-1);
        HANDLE t = CreateThread(NULL, 0, check_thread, ctx, 0, NULL);
        CloseHandle(t);
    }
    /* Разблокируем кнопку через 6 сек */
    SetTimer(g_hwnd, ID_TIMER_CHECK, 6000, NULL);
}

/* ── Запуск/остановка bypass ── */
static void start_bypass(void) {
    wd_engine_opts_t opts = {0};
    opts.opts.disorder  = 1;
    opts.opts.fake_ttl  = 5;
    opts.opts.tlsrec_split = 1;
    strncpy(opts.filter,
        "outbound and tcp.DstPort == 443 and tcp.PayloadLength > 0",
        sizeof(opts.filter)-1);

    if (wd_engine_start(&opts) != 0) {
        MessageBoxA(g_hwnd,
            "Не удалось запустить WinDivert.\nЗапусти программу от Администратора.",
            "Ошибка", MB_ICONERROR);
        return;
    }
    g_running = TRUE;
    g_dotColor = CLR_GREEN;
    SetWindowTextA(g_statusText, "Работает");
    EnableWindow(g_btnStart, FALSE);
    EnableWindow(g_btnStop,  TRUE);
    InvalidateRect(g_statusDot, NULL, TRUE);
    log_append("▶ DPI bypass запущен");
}

static void stop_bypass(void) {
    wd_engine_stop();
    g_running = FALSE;
    g_dotColor = CLR_GRAY;
    SetWindowTextA(g_statusText, "Остановлен");
    EnableWindow(g_btnStart, TRUE);
    EnableWindow(g_btnStop,  FALSE);
    InvalidateRect(g_statusDot, NULL, TRUE);
    for (int i = 0; i < N_SERVICES; i++) {
        g_svcColor[i] = CLR_GRAY;
        InvalidateRect(g_svcDot[i], NULL, TRUE);
    }
    log_append("■ Остановлен");
}

/* ── Кастомная отрисовка цветных кружков ── */
static LRESULT CALLBACK dot_proc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
    if (msg == WM_PAINT) {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hwnd, &ps);
        RECT rc; GetClientRect(hwnd, &rc);
        /* Фон */
        HBRUSH bg = CreateSolidBrush(CLR_PANEL);
        FillRect(hdc, &rc, bg); DeleteObject(bg);
        /* Кружок */
        COLORREF *col = (COLORREF *)GetWindowLongPtrA(hwnd, GWLP_USERDATA);
        COLORREF c = col ? *col : CLR_GRAY;
        HBRUSH br = CreateSolidBrush(c);
        SelectObject(hdc, br);
        SelectObject(hdc, GetStockObject(NULL_PEN));
        int cx = (rc.right - rc.left) / 2;
        int cy = (rc.bottom - rc.top) / 2;
        int r  = 7;
        Ellipse(hdc, cx-r, cy-r, cx+r, cy+r);
        DeleteObject(br);
        EndPaint(hwnd, &ps);
        return 0;
    }
    return DefWindowProcA(hwnd, msg, wp, lp);
}

/* ── Главный WndProc ── */
static LRESULT CALLBACK wnd_proc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
    switch (msg) {
    case WM_CREATE: {
        g_hwnd = hwnd;

        /* Шрифты */
        g_fontUI   = CreateFontA(16,0,0,0,FW_NORMAL,0,0,0,DEFAULT_CHARSET,
                        OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,CLEARTYPE_QUALITY,
                        DEFAULT_PITCH,"Segoe UI");
        g_fontBig  = CreateFontA(20,0,0,0,FW_BOLD,0,0,0,DEFAULT_CHARSET,
                        OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,CLEARTYPE_QUALITY,
                        DEFAULT_PITCH,"Segoe UI");
        g_fontMono = CreateFontA(14,0,0,0,FW_NORMAL,0,0,0,DEFAULT_CHARSET,
                        OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,CLEARTYPE_QUALITY,
                        FIXED_PITCH,"Consolas");

        /* Регистрируем класс кружка */
        WNDCLASSA wc = {0};
        wc.lpfnWndProc   = dot_proc;
        wc.hInstance     = GetModuleHandleA(NULL);
        wc.lpszClassName = "NTDot";
        wc.hbrBackground = CreateSolidBrush(CLR_PANEL);
        RegisterClassA(&wc);

        int x = 12, y = 10, W = 376;

        /* Заголовок */
        HWND title = CreateWindowA("STATIC","NeoTUN  —  DPI Bypass",
            WS_CHILD|WS_VISIBLE|SS_LEFT, x, y, W, 24, hwnd, NULL,
            GetModuleHandleA(NULL), NULL);
        SendMessageA(title, WM_SETFONT, (WPARAM)g_fontBig, TRUE);
        y += 32;

        /* Панель статуса */
        HWND pStatus = CreateWindowA("STATIC","",
            WS_CHILD|WS_VISIBLE|SS_OWNERDRAW,
            x, y, W, 40, hwnd, NULL, GetModuleHandleA(NULL), NULL);
        (void)pStatus;

        g_dotColor = CLR_GRAY;
        g_statusDot = CreateWindowA("NTDot","",
            WS_CHILD|WS_VISIBLE, x+8, y+8, 20, 20, hwnd,
            (HMENU)ID_STATUS_ICON, GetModuleHandleA(NULL), NULL);
        SetWindowLongPtrA(g_statusDot, GWLP_USERDATA, (LONG_PTR)&g_dotColor);

        g_statusText = CreateWindowA("STATIC","Остановлен",
            WS_CHILD|WS_VISIBLE|SS_LEFT,
            x+34, y+10, 200, 20, hwnd,
            (HMENU)ID_STATUS_TEXT, GetModuleHandleA(NULL), NULL);
        SendMessageA(g_statusText, WM_SETFONT, (WPARAM)g_fontUI, TRUE);
        y += 50;

        /* Панель сервисов */
        HWND lbl = CreateWindowA("STATIC","Сервисы:",
            WS_CHILD|WS_VISIBLE|SS_LEFT, x, y, 80, 18, hwnd, NULL,
            GetModuleHandleA(NULL), NULL);
        SendMessageA(lbl, WM_SETFONT, (WPARAM)g_fontUI, TRUE);
        y += 22;

        int sx = x;
        for (int i = 0; i < N_SERVICES; i++) {
            g_svcColor[i] = CLR_GRAY;
            g_svcDot[i] = CreateWindowA("NTDot","",
                WS_CHILD|WS_VISIBLE, sx, y+2, 16, 16, hwnd,
                NULL, GetModuleHandleA(NULL), NULL);
            SetWindowLongPtrA(g_svcDot[i], GWLP_USERDATA, (LONG_PTR)&g_svcColor[i]);

            g_svcLbl[i] = CreateWindowA("STATIC", SERVICES[i].name,
                WS_CHILD|WS_VISIBLE|SS_LEFT,
                sx+20, y, 80, 20, hwnd, NULL, GetModuleHandleA(NULL), NULL);
            SendMessageA(g_svcLbl[i], WM_SETFONT, (WPARAM)g_fontUI, TRUE);
            sx += 110;
        }

        g_btnCheck = CreateWindowA("BUTTON","Проверить",
            WS_CHILD|WS_VISIBLE|BS_PUSHBUTTON,
            W-80, y-2, 90, 26, hwnd,
            (HMENU)ID_BTN_CHECK, GetModuleHandleA(NULL), NULL);
        SendMessageA(g_btnCheck, WM_SETFONT, (WPARAM)g_fontUI, TRUE);
        y += 36;

        /* Кнопки старт/стоп */
        BOOL admin = IsUserAnAdmin();
        g_btnStart = CreateWindowA("BUTTON","▶  Запустить",
            WS_CHILD|WS_VISIBLE|BS_PUSHBUTTON|(admin?0:WS_DISABLED),
            x, y, 180, 32, hwnd,
            (HMENU)ID_BTN_START, GetModuleHandleA(NULL), NULL);
        SendMessageA(g_btnStart, WM_SETFONT, (WPARAM)g_fontUI, TRUE);

        g_btnStop = CreateWindowA("BUTTON","■  Остановить",
            WS_CHILD|WS_VISIBLE|BS_PUSHBUTTON|WS_DISABLED,
            x+188, y, 180, 32, hwnd,
            (HMENU)ID_BTN_STOP, GetModuleHandleA(NULL), NULL);
        SendMessageA(g_btnStop, WM_SETFONT, (WPARAM)g_fontUI, TRUE);
        y += 42;

        if (!admin) {
            HWND warn = CreateWindowA("STATIC",
                "⚠  Нет прав администратора — запусти от имени администратора",
                WS_CHILD|WS_VISIBLE|SS_LEFT,
                x, y, W, 18, hwnd, NULL, GetModuleHandleA(NULL), NULL);
            SendMessageA(warn, WM_SETFONT, (WPARAM)g_fontMono, TRUE);
            y += 22;
        }

        /* Лог */
        g_log = CreateWindowA("EDIT","",
            WS_CHILD|WS_VISIBLE|WS_VSCROLL|ES_MULTILINE|ES_READONLY|ES_AUTOVSCROLL,
            x, y, W, 120, hwnd,
            (HMENU)ID_LOG, GetModuleHandleA(NULL), NULL);
        SendMessageA(g_log, WM_SETFONT, (WPARAM)g_fontMono, TRUE);

        log_append("NeoTUN DPI Bypass готов к запуску.");
        break;
    }

    case WM_COMMAND:
        switch (LOWORD(wp)) {
        case ID_BTN_START: start_bypass(); break;
        case ID_BTN_STOP:  stop_bypass();  break;
        case ID_BTN_CHECK: do_check();     break;
        }
        break;

    case WM_TIMER:
        if (wp == ID_TIMER_CHECK) {
            KillTimer(hwnd, ID_TIMER_CHECK);
            EnableWindow(g_btnCheck, TRUE);
        }
        break;

    case WM_CTLCOLORSTATIC:
    case WM_CTLCOLOREDIT: {
        HDC hdc = (HDC)wp;
        SetBkColor(hdc, CLR_BG);
        SetTextColor(hdc, CLR_TEXT);
        static HBRUSH hbr = NULL;
        if (!hbr) hbr = CreateSolidBrush(CLR_BG);
        return (LRESULT)hbr;
    }

    case WM_ERASEBKGND: {
        HDC hdc = (HDC)wp;
        RECT rc; GetClientRect(hwnd, &rc);
        HBRUSH br = CreateSolidBrush(CLR_BG);
        FillRect(hdc, &rc, br);
        DeleteObject(br);
        return 1;
    }

    case WM_DESTROY:
        if (g_running) stop_bypass();
        DeleteObject(g_fontUI);
        DeleteObject(g_fontBig);
        DeleteObject(g_fontMono);
        PostQuitMessage(0);
        break;
    }
    return DefWindowProcA(hwnd, msg, wp, lp);
}

int gui_run(void) {
    INITCOMMONCONTROLSEX icc = { sizeof(icc), ICC_STANDARD_CLASSES };
    InitCommonControlsEx(&icc);

    WNDCLASSEXA wc = {0};
    wc.cbSize        = sizeof(wc);
    wc.lpfnWndProc   = wnd_proc;
    wc.hInstance     = GetModuleHandleA(NULL);
    wc.hbrBackground = CreateSolidBrush(CLR_BG);
    wc.lpszClassName = "NeoTUN";
    wc.hIcon         = LoadIconA(NULL, IDI_APPLICATION);
    wc.hCursor       = LoadCursorA(NULL, IDC_ARROW);
    RegisterClassExA(&wc);

    HWND hwnd = CreateWindowExA(
        0, "NeoTUN", "NeoTUN — DPI Bypass",
        WS_OVERLAPPED|WS_CAPTION|WS_SYSMENU|WS_MINIMIZEBOX,
        CW_USEDEFAULT, CW_USEDEFAULT, 420, 320,
        NULL, NULL, GetModuleHandleA(NULL), NULL);

    ShowWindow(hwnd, SW_SHOW);
    UpdateWindow(hwnd);

    MSG msg;
    while (GetMessageA(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessageA(&msg);
    }
    return (int)msg.wParam;
}

#endif /* _WIN32 */
