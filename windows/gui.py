import customtkinter as ctk
import subprocess
import threading
import socket
import ssl
import os
import sys
import ctypes
import math
import time

# ── paths ──────────────────────────────────────────────────────────────────────
if getattr(sys, "frozen", False):
    BASE = sys._MEIPASS
else:
    BASE = os.path.dirname(os.path.abspath(__file__))

BINARY = os.path.join(BASE, "neotun.exe")

# Режимы bypass
MODES = {
    "Всё":      "-w -t -s 2 -o -f 5",
    "YouTube":  "-w -t -s 2 -o -f 5 -Y",
    "Discord":  "-w -t -f 5 -D",
}

ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("blue")

# palette
BG      = "#070710"
SURF    = "#0D0D1A"
CARD    = "#111120"
BORDER  = "#1C1C32"
ACCENT  = "#4F7FFF"
ACCENT2 = "#7B5EA7"
GREEN   = "#00D26A"
GREEN_B = "#003D20"
RED     = "#FF4757"
TEXT    = "#E0E0F0"
MUTED   = "#3A3A5C"
MUTED2  = "#252540"
WHITE   = "#FFFFFF"

# ── helpers ────────────────────────────────────────────────────────────────────
def is_admin():
    try:    return bool(ctypes.windll.shell32.IsUserAnAdmin())
    except: return False

def relaunch_as_admin():
    ctypes.windll.shell32.ShellExecuteW(None,"runas",sys.executable," ".join(sys.argv),None,1)
    sys.exit(0)

def test_host(host, timeout=5):
    try:
        r = subprocess.run(
            ["curl","-s","-o","NUL","-w","%{http_code}",
             "--max-time",str(timeout),"--connect-timeout",str(timeout),
             "--ssl-no-revoke",f"https://{host}/"],
            capture_output=True,text=True,timeout=timeout+3,
            creationflags=subprocess.CREATE_NO_WINDOW)
        code = r.stdout.strip()
        if code.isdigit() and 100 <= int(code) < 600:
            return True
    except: pass
    try:
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        s = socket.create_connection((host,443),timeout=timeout)
        with ctx.wrap_socket(s,server_hostname=host) as t:
            t.sendall(f"HEAD / HTTP/1.0\r\nHost: {host}\r\n\r\n".encode())
            return len(t.recv(64)) > 0
    except: return False

# ── connect button ─────────────────────────────────────────────────────────────
class GradientButton(ctk.CTkButton):
    """Pill connect button — wraps CTkButton for stable cross-platform rendering."""
    def __init__(self, master, text, command=None, **kw):
        kw.pop("bg", None)  # CTkButton doesn't accept bg
        super().__init__(
            master,
            text=text,
            command=command,
            height=64,
            corner_radius=14,
            font=("Segoe UI", 14, "bold"),
            fg_color=ACCENT,
            hover_color="#3A6FEF",
            text_color=WHITE,
            **kw,
        )
        self._active = False

    def set_active(self, active: bool):
        self._active = active
        if active:
            self.configure(fg_color=GREEN, hover_color="#00A855")
        else:
            self.configure(fg_color=ACCENT, hover_color="#3A6FEF")

    def set_text(self, t):
        self.configure(text=t)

# ── dot indicator ──────────────────────────────────────────────────────────────
class DotIndicator(ctk.CTkFrame):
    def __init__(self, master, **kw):
        super().__init__(master, fg_color="transparent", **kw)
        self._dot = ctk.CTkLabel(self, text="●", font=("Segoe UI",11),
                                  text_color=MUTED)
        self._lbl = ctk.CTkLabel(self, text="ОСТАНОВЛЕН",
                                  font=("Segoe UI",10,"bold"), text_color=MUTED)
        self._dot.pack(side="left", padx=(0,4))
        self._lbl.pack(side="left")

    def set(self, running: bool):
        if running:
            self._dot.configure(text_color=GREEN)
            self._lbl.configure(text="РАБОТАЕТ", text_color=GREEN)
        else:
            self._dot.configure(text_color=MUTED)
            self._lbl.configure(text="ОСТАНОВЛЕН", text_color=MUTED)

# ── main app ───────────────────────────────────────────────────────────────────
class App(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("NeoTUN")
        self.geometry("460x580")
        self.resizable(False, False)
        self.configure(fg_color=BG)
        self.process  = None
        self._running = False
        self._mode    = "Всё"
        self._build()

    def _build(self):
        admin = is_admin()

        # ── admin bar ──
        if not admin:
            bar = ctk.CTkFrame(self, fg_color="#180808", corner_radius=0, height=32)
            bar.pack(fill="x")
            bar.pack_propagate(False)
            ctk.CTkLabel(bar, text="⚠  Нужны права администратора",
                         text_color="#FF6060", font=("Segoe UI",10)).pack(side="left",padx=12)
            ctk.CTkButton(bar, text="Перезапустить", width=110, height=22,
                          fg_color="#3A0808", hover_color="#5A1010",
                          text_color="#FF9090", font=("Segoe UI",9),
                          command=relaunch_as_admin).pack(side="right",padx=8,pady=5)

        # ── header ──
        hdr = ctk.CTkFrame(self, fg_color=SURF, corner_radius=0, height=60)
        hdr.pack(fill="x")
        hdr.pack_propagate(False)

        ctk.CTkLabel(hdr, text="Neo", font=("Segoe UI",22,"bold"),
                     text_color=WHITE).place(x=20, y=14)
        ctk.CTkLabel(hdr, text="TUN", font=("Segoe UI",22,"bold"),
                     text_color=ACCENT).place(x=58, y=14)
        ctk.CTkLabel(hdr, text="DPI Bypass  •  YouTube",
                     font=("Segoe UI",10), text_color=MUTED).place(x=22, y=38)

        self._indicator = DotIndicator(hdr)
        self._indicator.place(relx=1.0, x=-16, y=18, anchor="ne")

        # ── main content ──
        body = ctk.CTkFrame(self, fg_color=BG)
        body.pack(fill="both", expand=True, padx=20, pady=16)

        # big connect button
        self._btn = GradientButton(body, text="ПОДКЛЮЧИТЬ",
                                    command=self._toggle,
                                    bg=BG)
        self._btn.pack(fill="x", ipady=0)
        if not admin:
            self._btn.configure(state="disabled")

        # ── mode selector ──
        mode_frame = ctk.CTkFrame(body, fg_color=CARD, corner_radius=12)
        mode_frame.pack(fill="x", pady=(10, 0))

        ctk.CTkLabel(mode_frame, text="РЕЖИМ ОБХОДА",
                     font=("Segoe UI", 9), text_color=MUTED).pack(anchor="w", padx=14, pady=(10, 4))

        seg_frame = ctk.CTkFrame(mode_frame, fg_color=MUTED2, corner_radius=8)
        seg_frame.pack(fill="x", padx=10, pady=(0, 10))

        self._mode_btns = {}
        for label in MODES:
            btn = ctk.CTkButton(
                seg_frame, text=label,
                height=30, corner_radius=6,
                font=("Segoe UI", 11),
                fg_color=ACCENT if label == self._mode else "transparent",
                hover_color="#303055",
                text_color=WHITE if label == self._mode else MUTED,
                command=lambda l=label: self._set_mode(l)
            )
            btn.pack(side="left", fill="x", expand=True, padx=3, pady=3)
            self._mode_btns[label] = btn
        yt = ctk.CTkFrame(body, fg_color=CARD, corner_radius=14)
        yt.pack(fill="x", pady=(14,0))

        yt_l = ctk.CTkFrame(yt, fg_color="transparent")
        yt_l.pack(side="left", padx=16, pady=14)

        # youtube logo text
        yt_logo = ctk.CTkFrame(yt_l, fg_color="transparent")
        yt_logo.pack(anchor="w")
        ctk.CTkLabel(yt_logo, text="▶", font=("Segoe UI",14),
                     text_color=RED).pack(side="left", padx=(0,6))
        ctk.CTkLabel(yt_logo, text="YouTube", font=("Segoe UI",14,"bold"),
                     text_color=TEXT).pack(side="left")

        self._yt_lbl = ctk.CTkLabel(yt_l, text="Не проверено",
                                     font=("Segoe UI",11), text_color=MUTED)
        self._yt_lbl.pack(anchor="w", pady=(3,0))

        self._btn_check = ctk.CTkButton(yt, text="Проверить", width=96, height=34,
                                         corner_radius=10,
                                         fg_color=MUTED2, hover_color="#303055",
                                         text_color=TEXT, font=("Segoe UI",11),
                                         command=self._check_yt)
        self._btn_check.pack(side="right", padx=16)

        # ── info row ──
        info = ctk.CTkFrame(body, fg_color="transparent")
        info.pack(fill="x", pady=(12,0))

        self._mk_stat(info, "⚡", "МЕТОД",   "TLS Split + Fake TTL").pack(side="left",fill="x",expand=True,padx=(0,6))
        self._mk_stat(info, "🔒", "ПРОКСИ",  "Системный (WinDivert)").pack(side="left",fill="x",expand=True,padx=(6,0))

        # ── log ──
        log_wrap = ctk.CTkFrame(body, fg_color=CARD, corner_radius=14)
        log_wrap.pack(fill="both", expand=True, pady=(12,0))

        log_hdr = ctk.CTkFrame(log_wrap, fg_color="transparent")
        log_hdr.pack(fill="x", padx=14, pady=(10,0))
        ctk.CTkLabel(log_hdr, text="Журнал", font=("Segoe UI",10,"bold"),
                     text_color=MUTED).pack(side="left")
        self._btn_clear = ctk.CTkButton(log_hdr, text="Очистить", width=60, height=20,
                                         fg_color="transparent", hover_color=MUTED2,
                                         text_color=MUTED, font=("Segoe UI",9),
                                         command=self._clear_log)
        self._btn_clear.pack(side="right")

        self._log = ctk.CTkTextbox(log_wrap, font=("Consolas",9),
                                    fg_color="transparent", text_color="#4A4A70",
                                    corner_radius=0, border_width=0)
        self._log.pack(fill="both", expand=True, padx=10, pady=(4,10))
        self._log.configure(state="disabled")

    def _mk_stat(self, parent, icon, label, value):
        f = ctk.CTkFrame(parent, fg_color=CARD, corner_radius=12)
        ctk.CTkLabel(f, text=f"{icon}  {label}",
                     font=("Segoe UI",9), text_color=MUTED).pack(anchor="w",padx=14,pady=(12,0))
        ctk.CTkLabel(f, text=value, font=("Segoe UI",12,"bold"),
                     text_color="#6868A0").pack(anchor="w",padx=14,pady=(3,12))
        return f

    # ── mode ──
    def _set_mode(self, label):
        if self._running: return   # нельзя менять во время работы
        self._mode = label
        for l, btn in self._mode_btns.items():
            btn.configure(
                fg_color=ACCENT if l == label else "transparent",
                text_color=WHITE if l == label else MUTED
            )

    # ── toggle ──
    def _toggle(self):
        if self._running: self._stop()
        else:             self._start()

    def _start(self):
        if not os.path.exists(BINARY):
            self._log_line(f"[ERR] не найден: {BINARY}"); return
        args = MODES.get(self._mode, MODES["Всё"])
        try:
            self.process = subprocess.Popen(
                [BINARY] + args.split(),
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                text=True, creationflags=subprocess.CREATE_NO_WINDOW)
        except Exception as e:
            self._log_line(f"[ERR] {e}"); return

        self._running = True
        self._btn.set_active(True)
        self._btn.set_text("ОТКЛЮЧИТЬ")
        self._indicator.set(True)
        self._log_line(f"Запущен [{self._mode}]: {BINARY} {args}")
        threading.Thread(target=self._read_output, daemon=True).start()
        self.after(2500, self._check_yt)

    def _stop(self):
        if self.process:
            self.process.terminate()
            self.process = None
        self._running = False
        self._btn.set_active(False)
        self._btn.set_text("ПОДКЛЮЧИТЬ")
        self._indicator.set(False)
        self._yt_lbl.configure(text="Не проверено", text_color=MUTED)
        self._log_line("Остановлен.")

    def _read_output(self):
        proc = self.process
        if not proc: return
        for line in proc.stdout:
            self.after(0, self._log_line, line.rstrip())
        self.after(0, self._on_exit)

    def _on_exit(self):
        if self._running:
            self._running = False
            self.after(0, self._stop)

    # ── check ──
    def _check_yt(self):
        self._btn_check.configure(state="disabled", text="...")
        self._yt_lbl.configure(text="Проверяю...", text_color=MUTED)
        def _run():
            ok    = test_host("www.youtube.com")
            color = GREEN if ok else RED
            text  = "✓  Доступен" if ok else "✗  Заблокирован"
            self.after(0, lambda: self._yt_lbl.configure(text=text, text_color=color))
            self.after(0, lambda: self._btn_check.configure(state="normal", text="Проверить"))
        threading.Thread(target=_run, daemon=True).start()

    # ── log ──
    def _log_line(self, text):
        self._log.configure(state="normal")
        self._log.insert("end", text+"\n")
        self._log.see("end")
        self._log.configure(state="disabled")

    def _clear_log(self):
        self._log.configure(state="normal")
        self._log.delete("1.0","end")
        self._log.configure(state="disabled")

    def on_close(self):
        self._stop()
        self.destroy()


if __name__ == "__main__":
    app = App()
    app.protocol("WM_DELETE_WINDOW", app.on_close)
    app.mainloop()
