import customtkinter as ctk
import subprocess
import threading
import socket
import ssl
import os
import sys
import ctypes

# ── paths ──────────────────────────────────────────────────────────────────────
# When bundled by PyInstaller, data files land in sys._MEIPASS
if getattr(sys, "frozen", False):
    BASE = sys._MEIPASS
else:
    BASE = os.path.dirname(os.path.abspath(__file__))

BINARY = os.path.join(BASE, "neotun.exe")

DEFAULT_ARGS = "-w -t -s 2 -o -f 5"
TEST_TIMEOUT = 5

# ── appearance ─────────────────────────────────────────────────────────────────
ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("blue")

BG        = "#0E0E1C"
CARD      = "#1A1A2E"
ACCENT    = "#4F8EF7"
GREEN     = "#27AE60"
RED       = "#E74C3C"
TEXT      = "#CCCCEE"
MUTED     = "#555577"

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

def test_host(host, timeout=TEST_TIMEOUT):
    try:
        r = subprocess.run(
            ["curl", "-s", "-o", "NUL", "-w", "%{http_code}",
             "--max-time", str(timeout), "--connect-timeout", str(timeout),
             "--ssl-no-revoke", f"https://{host}/"],
            capture_output=True, text=True, timeout=timeout + 3,
            creationflags=subprocess.CREATE_NO_WINDOW
        )
        code = r.stdout.strip()
        if code.isdigit():
            return 100 <= int(code) < 600
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

# ── main window ────────────────────────────────────────────────────────────────
class App(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("NeoTUN - DPI")
        self.geometry("420x540")
        self.resizable(False, False)
        self.configure(fg_color=BG)
        self.process = None
        self._build()

    def _build(self):
        admin = is_admin()

        # ── admin warning ──
        if not admin:
            warn = ctk.CTkFrame(self, fg_color="#3A1010", corner_radius=8)
            warn.pack(fill="x", padx=16, pady=(12, 0))
            ctk.CTkLabel(warn, text="⚠  Нет прав администратора",
                         text_color="#FF6B6B", font=("Segoe UI", 11)).pack(side="left", padx=12, pady=6)
            ctk.CTkButton(warn, text="Перезапустить", width=130, height=28,
                          fg_color="#7A2020", hover_color="#9A3030",
                          command=relaunch_as_admin).pack(side="right", padx=8, pady=4)

        # ── header ──
        ctk.CTkLabel(self, text="NeoTUN", font=("Segoe UI", 26, "bold"),
                     text_color="white").pack(pady=(20, 0))
        ctk.CTkLabel(self, text="DPI BYPASS", font=("Segoe UI", 11),
                     text_color=MUTED).pack()

        # ── big toggle button ──
        self.btn_toggle = ctk.CTkButton(
            self, text="ЗАПУСТИТЬ", width=160, height=160,
            corner_radius=80,
            font=("Segoe UI", 15, "bold"),
            fg_color=CARD, hover_color="#252540",
            border_width=2, border_color="#3A3A5C",
            text_color=TEXT,
            command=self._toggle
        )
        self.btn_toggle.pack(pady=20)

        # ── status label ──
        self.lbl_status = ctk.CTkLabel(self, text="● Остановлен",
                                        font=("Segoe UI", 13),
                                        text_color=MUTED)
        self.lbl_status.pack()

        # ── youtube check card ──
        card = ctk.CTkFrame(self, fg_color=CARD, corner_radius=12)
        card.pack(fill="x", padx=16, pady=(16, 0))

        row = ctk.CTkFrame(card, fg_color="transparent")
        row.pack(fill="x", padx=14, pady=10)

        ctk.CTkLabel(row, text="YouTube", font=("Segoe UI", 13, "bold"),
                     text_color=TEXT).pack(side="left")

        self.lbl_yt = ctk.CTkLabel(row, text="—", font=("Segoe UI", 12),
                                    text_color=MUTED)
        self.lbl_yt.pack(side="left", padx=10)

        self.btn_check = ctk.CTkButton(row, text="Проверить", width=100, height=28,
                                        fg_color="#252540", hover_color="#303050",
                                        text_color=TEXT, font=("Segoe UI", 11),
                                        command=self._check_yt)
        self.btn_check.pack(side="right")

        # ── log ──
        self.log = ctk.CTkTextbox(self, height=120, font=("Consolas", 9),
                                   fg_color=CARD, text_color="#8888AA",
                                   corner_radius=10, border_width=0)
        self.log.pack(fill="x", padx=16, pady=12)
        self.log.configure(state="disabled")

        if not admin:
            self.btn_toggle.configure(state="disabled")

    # ── toggle ──
    def _toggle(self):
        if self.process:
            self._stop()
        else:
            self._start()

    def _start(self):
        if not os.path.exists(BINARY):
            self._log(f"[ERR] neotun.exe не найден: {BINARY}")
            return
        cmd = [BINARY] + DEFAULT_ARGS.split()
        try:
            self.process = subprocess.Popen(
                cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                text=True, creationflags=subprocess.CREATE_NO_WINDOW
            )
        except Exception as e:
            self._log(f"[ERR] {e}")
            return

        self.btn_toggle.configure(text="ОСТАНОВИТЬ", fg_color="#1A3A1A",
                                   hover_color="#1E4A1E", border_color=GREEN,
                                   text_color=GREEN)
        self.lbl_status.configure(text="● Работает", text_color=GREEN)
        self._log(f"Запущен: {' '.join(cmd)}")
        threading.Thread(target=self._read_output, daemon=True).start()
        # Автопроверка YouTube через 3 секунды
        self.after(3000, self._check_yt)

    def _stop(self):
        if self.process:
            self.process.terminate()
            self.process = None
        self.btn_toggle.configure(text="ЗАПУСТИТЬ", fg_color=CARD,
                                   hover_color="#252540", border_color="#3A3A5C",
                                   text_color=TEXT)
        self.lbl_status.configure(text="● Остановлен", text_color=MUTED)
        self.lbl_yt.configure(text="—", text_color=MUTED)
        self._log("Остановлен.")

    def _read_output(self):
        proc = self.process
        if not proc: return
        for line in proc.stdout:
            self.after(0, self._log, line.rstrip())
        self.after(0, self._on_exit)

    def _on_exit(self):
        if self.process:
            self.process = None
            self.after(0, self._stop)

    # ── check ──
    def _check_yt(self):
        self.btn_check.configure(state="disabled", text="...")
        self.lbl_yt.configure(text="проверяю...", text_color=MUTED)
        def _run():
            ok = test_host("www.youtube.com")
            color = GREEN if ok else RED
            text  = "✓ Работает" if ok else "✗ Заблокирован"
            self.after(0, self.lbl_yt.configure, {"text": text, "text_color": color})
            self.after(0, self.btn_check.configure, {"state": "normal", "text": "Проверить"})
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
