#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#define UNICODE
#define _UNICODE
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

#define ID_BTN_START  101
#define ID_BTN_STOP   102
#define ID_BTN_CHECK  103
#define ID_LOG        104
#define ID_TIMER_CHK  1

#define CLR_GREEN  RGB(39,174,96)
#define CLR_RED    RGB(192,57,43)
#define CLR_GRAY   RGB(150,150,150)
#define CLR_BG     RGB(30,30,46)
#define CLR_TEXT   RGB(220,220,220)

static HWND g_hwnd;
static HWND g_btnStart, g_btnStop, g_btnCheck;
static HWND g_log, g_statusText, g_statusDot;
static HFONT g_fontUI, g_fontMono, g_fontBig;
static COLORREF g_dotColor = 0;
static BOOL g_running = FALSE;
static HBRUSH g_hbrBg = NULL;

typedef struct { const wchar_t *name; const char *host; } Service;
static Service SERVICES[] = {
    {L"YouTube",   "www.youtube.com"},
    {L"Discord",   "discord.com"},
    {L"Speedtest", "www.speedtest.net"},
};
#define N_SVC 3
static HWND      g_svcDot[N_SVC];
static COLORREF  g_svcColor[N_SVC];

/* ── Лог ── */
static void log_w(const wchar_t *text) {
    int len = GetWindowTextLengthW(g_log);
    SendMessageW(g_log, EM_SETSEL, len, len);
    SendMessageW(g_log, EM_REPLACESEL, FALSE, (LPARAM)text);
    SendMessageW(g_log, EM_REPLACESEL, FALSE, (LPARAM)L"\r\n");
    SendMessageW(g_log, EM_SCROLLCARET, 0, 0);
}

/* ── Класс кружка ── */
static LRESULT CALLBACK DotProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
    if (msg == WM_PAINT) {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hwnd, &ps);
        RECT rc; GetClientRect(hwnd, &rc);
        FillRect(hdc, &rc, g_hbrBg);
        COLORREF *col = (COLORREF *)GetWindowLongPtrW(hwnd, GWLP_USERDATA);
        COLORREF c = col ? *col : CLR_GRAY;
        HBRUSH br = CreateSolidBrush(c);
        SelectObject(hdc, br);
        SelectObject(hdc, GetStockObject(NULL_PEN));
        int cx = rc.right/2, cy = rc.bottom/2, r = 7;
        Ellipse(hdc, cx-r, cy-r, cx+r, cy+r);
        DeleteObject(br);
        EndPaint(hwnd, &ps);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wp, lp);
}

/* ── Проверка сервиса ── */
typedef struct { int idx; char host[128]; } CheckCtx;
static DWORD WINAPI CheckThread(LPVOID param) {
    CheckCtx *ctx = (CheckCtx *)param;
    BOOL ok = FALSE;
    struct addrinfo hints = {0}, *res = NULL;
    hints.ai_family   = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    if (getaddrinfo(ctx->host, "443", &hints, &res) == 0 && res) {
        SOCKET s = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
        if (s != INVALID_SOCKET) {
            DWORD tv = 4000;
            setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, (char*)&tv, sizeof(tv));
            setsockopt(s, SOL_SOCKET, SO_SNDTIMEO, (char*)&tv, sizeof(tv));
            if (connect(s, res->ai_addr, (int)res->ai_addrlen) == 0) ok = TRUE;
            closesocket(s);
        }
        freeaddrinfo(res);
    }
    g_svcColor[ctx->idx] = ok ? CLR_GREEN : CLR_RED;
    InvalidateRect(g_svcDot[ctx->idx], NULL, TRUE);
    free(ctx);
    return 0;
}

static void do_check(void) {
    log_w(L"Проверяю...");
    EnableWindow(g_btnCheck, FALSE);
    for (int i = 0; i < N_SVC; i++) {
        g_svcColor[i] = CLR_GRAY;
        InvalidateRect(g_svcDot[i], NULL, TRUE);
        CheckCtx *ctx = malloc(sizeof(CheckCtx));
        ctx->idx = i;
        strncpy(ctx->host, SERVICES[i].host, sizeof(ctx->host)-1);
        CloseHandle(CreateThread(NULL, 0, CheckThread, ctx, 0, NULL));
    }
    SetTimer(g_hwnd, ID_TIMER_CHK, 6000, NULL);
}

/* ── Bypass ── */
static void start_bypass(void) {
    wd_engine_opts_t opts = {0};
    opts.opts.disorder     = 1;
    opts.opts.fake_ttl     = 5;
    opts.opts.tlsrec_split = 1;
    strncpy(opts.filter,
        "outbound and tcp.DstPort == 443 and tcp.PayloadLength > 0",
        sizeof(opts.filter)-1);
    if (wd_engine_start(&opts) != 0) {
        MessageBoxW(g_hwnd,
            L"Не удалось запустить WinDivert.\nЗапусти программу от имени Администратора.",
            L"Ошибка", MB_ICONERROR);
        return;
    }
    g_running  = TRUE;
    g_dotColor = CLR_GREEN;
    SetWindowTextW(g_statusText, L"Работает");
    EnableWindow(g_btnStart, FALSE);
    EnableWindow(g_btnStop,  TRUE);
    InvalidateRect(g_statusDot, NULL, TRUE);
    log_w(L"▶ DPI bypass запущен");
}

static void stop_bypass(void) {
    wd_engine_stop();
    g_running  = FALSE;
    g_dotColor = CLR_GRAY;
    SetWindowTextW(g_statusText, L"Остановлен");
    EnableWindow(g_btnStart, TRUE);
    EnableWindow(g_btnStop,  FALSE);
    InvalidateRect(g_statusDot, NULL, TRUE);
    for (int i = 0; i < N_SVC; i++) {
        g_svcColor[i] = CLR_GRAY;
        InvalidateRect(g_svcDot[i], NULL, TRUE);
    }
    log_w(L"■ Остановлен");
}

/* ── WndProc ── */
static LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
    switch (msg) {
    case WM_CREATE: {
        g_hwnd  = hwnd;
        g_hbrBg = CreateSolidBrush(CLR_BG);

        g_fontBig  = CreateFontW(20,0,0,0,FW_BOLD,0,0,0,DEFAULT_CHARSET,
                       OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,CLEARTYPE_QUALITY,
                       DEFAULT_PITCH, L"Segoe UI");
        g_fontUI   = CreateFontW(16,0,0,0,FW_NORMAL,0,0,0,DEFAULT_CHARSET,
                       OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,CLEARTYPE_QUALITY,
                       DEFAULT_PITCH, L"Segoe UI");
        g_fontMono = CreateFontW(14,0,0,0,FW_NORMAL,0,0,0,DEFAULT_CHARSET,
                       OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,CLEARTYPE_QUALITY,
                       FIXED_PITCH, L"Consolas");

        /* Регистрируем класс кружка */
        WNDCLASSW wc = {0};
        wc.lpfnWndProc   = DotProc;
        wc.hInstance     = GetModuleHandleW(NULL);
        wc.lpszClassName = L"NTDot";
        wc.hbrBackground = g_hbrBg;
        RegisterClassW(&wc);

        HINSTANCE hi = GetModuleHandleW(NULL);
        int x = 14, y = 12, W = 372;

        /* Заголовок */
        HWND h = CreateWindowW(L"STATIC", L"NeoTUN — DPI Bypass",
            WS_CHILD|WS_VISIBLE|SS_LEFT, x, y, W, 26, hwnd, NULL, hi, NULL);
        SendMessageW(h, WM_SETFONT, (WPARAM)g_fontBig, TRUE);
        y += 34;

        /* Статус */
        g_dotColor = CLR_GRAY;
        g_statusDot = CreateWindowW(L"NTDot", L"",
            WS_CHILD|WS_VISIBLE, x, y+2, 18, 18, hwnd,
            (HMENU)ID_BTN_START+10, hi, NULL);
        SetWindowLongPtrW(g_statusDot, GWLP_USERDATA, (LONG_PTR)&g_dotColor);

        g_statusText = CreateWindowW(L"STATIC", L"Остановлен",
            WS_CHILD|WS_VISIBLE|SS_LEFT, x+26, y, 200, 22, hwnd, NULL, hi, NULL);
        SendMessageW(g_statusText, WM_SETFONT, (WPARAM)g_fontUI, TRUE);
        y += 34;

        /* Сервисы */
        h = CreateWindowW(L"STATIC", L"Сервисы:",
            WS_CHILD|WS_VISIBLE|SS_LEFT, x, y, 80, 20, hwnd, NULL, hi, NULL);
        SendMessageW(h, WM_SETFONT, (WPARAM)g_fontUI, TRUE);
        y += 22;

        int sx = x;
        for (int i = 0; i < N_SVC; i++) {
            g_svcColor[i] = CLR_GRAY;
            g_svcDot[i] = CreateWindowW(L"NTDot", L"",
                WS_CHILD|WS_VISIBLE, sx, y+2, 16, 16, hwnd, NULL, hi, NULL);
            SetWindowLongPtrW(g_svcDot[i], GWLP_USERDATA, (LONG_PTR)&g_svcColor[i]);
            HWND lbl = CreateWindowW(L"STATIC", SERVICES[i].name,
                WS_CHILD|WS_VISIBLE|SS_LEFT, sx+20, y, 80, 20, hwnd, NULL, hi, NULL);
            SendMessageW(lbl, WM_SETFONT, (WPARAM)g_fontUI, TRUE);
            sx += 110;
        }

        g_btnCheck = CreateWindowW(L"BUTTON", L"Проверить",
            WS_CHILD|WS_VISIBLE|BS_PUSHBUTTON,
            W-76, y-2, 88, 26, hwnd, (HMENU)ID_BTN_CHECK, hi, NULL);
        SendMessageW(g_btnCheck, WM_SETFONT, (WPARAM)g_fontUI, TRUE);
        y += 36;

        /* Кнопки */
        BOOL admin = IsUserAnAdmin();
        g_btnStart = CreateWindowW(L"BUTTON", L"▶  Запустить",
            WS_CHILD|WS_VISIBLE|BS_PUSHBUTTON|(admin?0:WS_DISABLED),
            x, y, 178, 32, hwnd, (HMENU)ID_BTN_START, hi, NULL);
        SendMessageW(g_btnStart, WM_SETFONT, (WPARAM)g_fontUI, TRUE);

        g_btnStop = CreateWindowW(L"BUTTON", L"■  Остановить",
            WS_CHILD|WS_VISIBLE|BS_PUSHBUTTON|WS_DISABLED,
            x+186, y, 178, 32, hwnd, (HMENU)ID_BTN_STOP, hi, NULL);
        SendMessageW(g_btnStop, WM_SETFONT, (WPARAM)g_fontUI, TRUE);
        y += 42;

        if (!admin) {
            h = CreateWindowW(L"STATIC",
                L"⚠  Запусти от имени Администратора",
                WS_CHILD|WS_VISIBLE|SS_LEFT, x, y, W, 18, hwnd, NULL, hi, NULL);
            SendMessageW(h, WM_SETFONT, (WPARAM)g_fontMono, TRUE);
            y += 22;
        }

        /* Лог */
        g_log = CreateWindowW(L"EDIT", L"",
            WS_CHILD|WS_VISIBLE|WS_VSCROLL|ES_MULTILINE|ES_READONLY|ES_AUTOVSCROLL,
            x, y, W, 110, hwnd, (HMENU)ID_LOG, hi, NULL);
        SendMessageW(g_log, WM_SETFONT, (WPARAM)g_fontMono, TRUE);

        log_w(L"NeoTUN DPI Bypass готов к запуску.");
        if (!admin) log_w(L"Нет прав администратора!");
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
        if (wp == ID_TIMER_CHK) {
            KillTimer(hwnd, ID_TIMER_CHK);
            EnableWindow(g_btnCheck, TRUE);
        }
        break;

    case WM_CTLCOLORSTATIC:
    case WM_CTLCOLOREDIT: {
        HDC hdc = (HDC)wp;
        SetBkColor(hdc, CLR_BG);
        SetTextColor(hdc, CLR_TEXT);
        return (LRESULT)g_hbrBg;
    }

    case WM_ERASEBKGND: {
        RECT rc; GetClientRect(hwnd, &rc);
        FillRect((HDC)wp, &rc, g_hbrBg);
        return 1;
    }

    case WM_DESTROY:
        if (g_running) stop_bypass();
        DeleteObject(g_fontUI);
        DeleteObject(g_fontBig);
        DeleteObject(g_fontMono);
        DeleteObject(g_hbrBg);
        PostQuitMessage(0);
        break;
    }
    return DefWindowProcW(hwnd, msg, wp, lp);
}

int gui_run(void) {
    INITCOMMONCONTROLSEX icc = { sizeof(icc), ICC_STANDARD_CLASSES };
    InitCommonControlsEx(&icc);

    WNDCLASSEXW wc = {0};
    wc.cbSize        = sizeof(wc);
    wc.lpfnWndProc   = WndProc;
    wc.hInstance     = GetModuleHandleW(NULL);
    wc.hbrBackground = CreateSolidBrush(CLR_BG);
    wc.lpszClassName = L"NeoTUN";
    wc.hIcon         = LoadIconW(NULL, IDI_APPLICATION);
    wc.hCursor       = LoadCursorW(NULL, IDC_ARROW);
    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowExW(
        0, L"NeoTUN", L"NeoTUN — DPI Bypass",
        WS_OVERLAPPED|WS_CAPTION|WS_SYSMENU|WS_MINIMIZEBOX,
        CW_USEDEFAULT, CW_USEDEFAULT, 420, 340,
        NULL, NULL, GetModuleHandleW(NULL), NULL);

    ShowWindow(hwnd, SW_SHOW);
    UpdateWindow(hwnd);

    MSG msg;
    while (GetMessageW(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return (int)msg.wParam;
}

#endif /* _WIN32 */
