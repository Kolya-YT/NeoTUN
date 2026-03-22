import customtkinter as ctk
import subprocess
import threading
import socket
import ssl
import os
import sys
import ctypes
import time

# ── paths ──────────────────────────────────────────────────────────────────────
if getattr(sys, "frozen", False):
    BASE = sys._MEIPASS
else:
    BASE = os.path.dirname(os.path.abspath(__file__))

BINARY = os.path.join(BASE, "neotun.exe")
ARGS   = "-w -t -s 2 -o -f 5"

# ── theme ──────────────────────────────────────────────────────────────────────
ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("blue")

BG       = "#08080F"
SURFACE  = "#0F0F1A"
CARD     = "#13131E"
BORDER   = "#1E1E30"
ACCENT   = "#5B8DEF"
GREEN    = "#2ECC71"
GREEN_DIM= "#1A4A2E"
RED      = "#E74C3C"
TEXT     = "#D0D0E8"
MUTED    = "#404060"
MUTED2   = "#2A2A40"

# ── helpers ────────────────────────────────────────────────────────────────────
def is_admin():
    try:
        return bool(ctypes.windll.shell32.IsUserAnAdmin())
    except Exception:
        return False

def relaunch_as_admin():
    ctypes.windll.shell32.ShellExecuteW(
        None, "runas", sys.executable, " ".join(sys.argv), None, 1)
    sys.exit(0)

def test_host(host, timeout=5):
    try:
        r = subprocess.run(
            ["curl", "-s", "-o", "NUL", "-w", "%{http_code}",
             "--max-time", str(timeout), "--connect-timeout", str(timeout),
             "--ssl-no-revoke", f"https://{host}/"],
            capture_output=True, text=True, timeout=timeout + 3,
            creationflags=subprocess.CREATE_NO_WINDOW
        )
        code = r.stdout.strip()
        if code.isdigit() and 100 <= int(code) < 600:
            return True
    except Exception:
        pass
    try:
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        s = socket.create_connection((host, 443), timeout=timeout)
        with ctx.wrap_socket(s, server_hostname=host) as t:
            t.sendall(f"HEAD / HTTP/1.0\r\nHost: {host}\r\n\r\n".encode())
            return len(t.recv(64)) > 0
    except Exception:
        return False

# ── app ────────────────────────────────────────────────────────────────────────
class App(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("NeoTUN")
        self.geometry("480x560")
        self.resizable(False, False)
        self.configure(fg_color=BG)
        self.process = None
        self._running = False
        self._dot_count = 0
        self._build()

    def _build(self):
        admin = is_admin()

        # ── admin bar ──
        if not admin:
            bar = ctk.CTkFrame(self, fg_color="#1A0A0A", corner_radius=0, height=36)
            bar.pack(fill="x")
            bar.pack_propagate(False)
            ctk.CTkLabel(bar, text="⚠  Запустите от имени администратора",
                         text_color="#CC4444", font=("Segoe UI", 11)).pack(side="left", padx=14)
            ctk.CTkButton(bar, text="Перезапустить", width=120, height=24,
                          fg_color="#3A1010", hover_color="#5A1818",
                          text_color="#FF8888", font=("Segoe UI", 10),
                          command=relaunch_as_admin).pack(side="right", padx=10, pady=6)

        # ── header ──
        header = ctk.CTkFrame(self, fg_color=SURFACE, corner_radius=0, height=64)
        header.pack(fill="x")
        header.pack_propagate(False)

        ctk.CTkLabel(header, text="NeoTUN",
                     font=("Segoe UI", 20, "bold"), text_color="white").place(x=20, y=12)
        ctk.CTkLabel(header, text="DPI BYPASS",
                     font=("Segoe UI", 9), text_color=MUTED).place(x=22, y=38)

        self.lbl_badge = ctk.CTkLabel(header, text="● ОСТАНОВЛЕН",
                                       font=("Segoe UI", 10, "bold"),
                                       text_color=MUTED,
                                       fg_color=MUTED2, corner_radius=10,
                                       padx=10, pady=3)
        self.lbl_badge.place(relx=1.0, x=-16, y=20, anchor="ne")

        # ── big button area ──
        center = ctk.CTkFrame(self, fg_color=BG)
        center.pack(fill="x", padx=24, pady=(28, 0))

        self.btn_toggle = ctk.CTkButton(
            center,
            text="ПОДКЛЮЧИТЬ",
            width=432, height=72,
            corner_radius=16,
            font=("Segoe UI", 16, "bold"),
            fg_color=CARD,
            hover_color="#1A1A2A",
            border_width=1,
            border_color=BORDER,
            text_color=MUTED,
            command=self._toggle
        )
        self.btn_toggle.pack()

        if not admin:
            self.btn_toggle.configure(state="disabled", text_color=MUTED)

        # ── youtube card ──
        yt_card = ctk.CTkFrame(self, fg_color=CARD, corner_radius=14)
        yt_card.pack(fill="x", padx=24, pady=(16, 0))

        yt_inner = ctk.CTkFrame(yt_card, fg_color="transparent")
        yt_inner.pack(fill="x", padx=16, pady=14)

        left = ctk.CTkFrame(yt_inner, fg_color="transparent")
        left.pack(side="left", fill="y")

        ctk.CTkLabel(left, text="YouTube",
                     font=("Segoe UI", 14, "bold"), text_color=TEXT).pack(anchor="w")
        self.lbl_yt_status = ctk.CTkLabel(left, text="Не проверено",
                                           font=("Segoe UI", 11), text_color=MUTED)
        self.lbl_yt_status.pack(anchor="w", pady=(2, 0))

        self.btn_check = ctk.CTkButton(yt_inner, text="Проверить",
                                        width=100, height=32,
                                        corner_radius=8,
                                        fg_color=MUTED2, hover_color="#303050",
                                        text_color=TEXT, font=("Segoe UI", 11),
                                        command=self._check_yt)
        self.btn_check.pack(side="right")

        # ── info cards row ──
        row = ctk.CTkFrame(self, fg_color="transparent")
        row.pack(fill="x", padx=24, pady=(12, 0))

        self._make_info_card(row, "РЕЖИМ", "TLS Split + OOB").pack(side="left", fill="x", expand=True, padx=(0, 6))
        self._make_info_card(row, "ПРОКСИ", "Прямое подключение").pack(side="left", fill="x", expand=True, padx=(6, 0))

        # ── log ──
        log_frame = ctk.CTkFrame(self, fg_color=CARD, corner_radius=14)
        log_frame.pack(fill="both", expand=True, padx=24, pady=(12, 20))

        ctk.CTkLabel(log_frame, text="Журнал",
                     font=("Segoe UI", 10), text_color=MUTED).pack(anchor="w", padx=14, pady=(10, 0))

        self.log = ctk.CTkTextbox(log_frame, font=("Consolas", 9),
                                   fg_color="transparent", text_color="#505070",
                                   corner_radius=0, border_width=0)
        self.log.pack(fill="both", expand=True, padx=8, pady=(0, 8))
        self.log.configure(state="disabled")

    def _make_info_card(self, parent, label, value):
        f = ctk.CTkFrame(parent, fg_color=CARD, corner_radius=12)
        ctk.CTkLabel(f, text=label, font=("Segoe UI", 9),
                     text_color=MUTED).pack(anchor="w", padx=14, pady=(12, 0))
        ctk.CTkLabel(f, text=value, font=("Segoe UI", 12, "bold"),
                     text_color="#7070A0").pack(anchor="w", padx=14, pady=(2, 12))
        return f

    # ── toggle ──
    def _toggle(self):
        if self._running:
            self._stop()
        else:
            self._start()

    def _start(self):
        if not os.path.exists(BINARY):
            self._log(f"[ERR] neotun.exe не найден: {BINARY}")
            return
        cmd = [BINARY] + ARGS.split()
        try:
            self.process = subprocess.Popen(
                cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                text=True, creationflags=subprocess.CREATE_NO_WINDOW
            )
        except Exception as e:
            self._log(f"[ERR] {e}")
            return

        self._running = True
        self.btn_toggle.configure(
            text="ОТКЛЮЧИТЬ",
            fg_color=GREEN_DIM,
            hover_color="#1E3A24",
            border_color=GREEN,
            text_color=GREEN
        )
        self.lbl_badge.configure(text="● РАБОТАЕТ", text_color=GREEN, fg_color="#0D2A18")
        self._log(f"Запущен: {' '.join(cmd)}")
        threading.Thread(target=self._read_output, daemon=True).start()
        self.after(2500, self._check_yt)

    def _stop(self):
        if self.process:
            self.process.terminate()
            self.process = None
        self._running = False
        self.btn_toggle.configure(
            text="ПОДКЛЮЧИТЬ",
            fg_color=CARD,
            hover_color="#1A1A2A",
            border_color=BORDER,
            text_color=MUTED
        )
        self.lbl_badge.configure(text="● ОСТАНОВЛЕН", text_color=MUTED, fg_color=MUTED2)
        self.lbl_yt_status.configure(text="Не проверено", text_color=MUTED)
        self._log("Остановлен.")

    def _read_output(self):
        proc = self.process
        if not proc:
            return
        for line in proc.stdout:
            self.after(0, self._log, line.rstrip())
        self.after(0, self._on_exit)

    def _on_exit(self):
        if self._running:
            self._running = False
            self.after(0, self._stop)

    # ── check ──
    def _check_yt(self):
        self.btn_check.configure(state="disabled", text="...")
        self.lbl_yt_status.configure(text="Проверяю...", text_color=MUTED)
        def _run():
            ok = test_host("www.youtube.com")
            color = GREEN if ok else RED
            text  = "✓ Доступен" if ok else "✗ Заблокирован"
            self.after(0, lambda: self.lbl_yt_status.configure(text=text, text_color=color))
            self.after(0, lambda: self.btn_check.configure(state="normal", text="Проверить"))
        threading.Thread(target=_run, daemon=True).start()

    # ── log ──
    def _log(self, text):
        self.log.configure(state="normal")
        self.log.insert("end", text + "\n")
        self.log.see("end")
        self.log.configure(state="disabled")

    def on_close(self):
        self._stop()
        self.destroy()


if __name__ == "__main__":
    app = App()
    app.protocol("WM_DELETE_WINDOW", app.on_close)
    app.mainloop()
