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
ARGS   = "-w -t -s 2 -o -f 5"

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

# ── canvas gradient button ─────────────────────────────────────────────────────
class GradientButton(ctk.CTkCanvas):
    """A wide pill button with a left→right gradient and hover effect."""
    def __init__(self, master, text, command=None, **kw):
        super().__init__(master, highlightthickness=0, bd=0,
                         height=64, **kw)
        self._text    = text
        self._command = command
        self._hover   = False
        self._colors  = (ACCENT, ACCENT2)   # idle gradient
        self.bind("<Configure>",    self._draw)
        self.bind("<Enter>",        self._on_enter)
        self.bind("<Leave>",        self._on_leave)
        self.bind("<ButtonPress-1>",self._on_press)
        self._draw()

    def _draw(self, *_):
        self.delete("all")
        w = self.winfo_width()  or 400
        h = self.winfo_height() or 64
        r = 14   # corner radius

        c1, c2 = self._colors
        # horizontal gradient via thin vertical strips
        steps = 80
        for i in range(steps):
            t  = i / steps
            r1 = int(int(c1[1:3],16)*(1-t) + int(c2[1:3],16)*t)
            g1 = int(int(c1[3:5],16)*(1-t) + int(c2[3:5],16)*t)
            b1 = int(int(c1[5:7],16)*(1-t) + int(c2[5:7],16)*t)
            col = f"#{r1:02x}{g1:02x}{b1:02x}"
            x0  = i*(w/steps)
            x1  = (i+1)*(w/steps)+1
            self.create_rectangle(x0, 0, x1, h, fill=col, outline="")

        # rounded mask (overdraw corners with bg)
        bg = self._get_bg()
        for cx,cy in [(0,0),(w,0),(0,h),(w,h)]:
            self.create_arc(cx-r*2,cy-r*2,cx+r*2,cy+r*2,
                            start=0,extent=360,fill=bg,outline=bg)
        # re-draw rounded rect outline
        self.create_rounded_rect(0,0,w,h,r)

        # text
        self.create_text(w//2, h//2, text=self._text,
                         fill=WHITE, font=("Segoe UI",14,"bold"))

    def create_rounded_rect(self, x1,y1,x2,y2,r):
        self.create_arc(x1,y1,x1+2*r,y1+2*r,start=90, extent=90,style="arc",outline="",width=0)
        self.create_arc(x2-2*r,y1,x2,y1+2*r,start=0,  extent=90,style="arc",outline="",width=0)
        self.create_arc(x1,y2-2*r,x1+2*r,y2,start=180,extent=90,style="arc",outline="",width=0)
        self.create_arc(x2-2*r,y2-2*r,x2,y2,start=270,extent=90,style="arc",outline="",width=0)

    def _get_bg(self):
        try:    return self.master.cget("fg_color")[1]
        except: return BG

    def _on_enter(self,*_):
        self._colors = ("#6B9FFF","#9B7EC7")
        self._draw()

    def _on_leave(self,*_):
        if not self._active_colors_set:
            self._colors = (ACCENT, ACCENT2)
        self._draw()

    def _on_press(self,*_):
        if self._command: self._command()

    _active_colors_set = False

    def set_active(self, active: bool):
        if active:
            self._colors = (GREEN, "#007A40")
            self._active_colors_set = True
        else:
            self._colors = (ACCENT, ACCENT2)
            self._active_colors_set = False
        self._draw()

    def set_text(self, t):
        self._text = t
        self._draw()

    def configure(self, **kw):
        if "state" in kw:
            self._disabled = kw.pop("state") == "disabled"
        super().configure(**kw)

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

        # ── youtube row ──
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

        self._mk_stat(info, "⚡", "РЕЖИМ",   "TLS Split + OOB").pack(side="left",fill="x",expand=True,padx=(0,6))
        self._mk_stat(info, "🔒", "ПРОКСИ",  "SOCKS5 :1080").pack(side="left",fill="x",expand=True,padx=(6,0))

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

    # ── toggle ──
    def _toggle(self):
        if self._running: self._stop()
        else:             self._start()

    def _start(self):
        if not os.path.exists(BINARY):
            self._log_line(f"[ERR] не найден: {BINARY}"); return
        try:
            self.process = subprocess.Popen(
                [BINARY]+ARGS.split(),
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                text=True, creationflags=subprocess.CREATE_NO_WINDOW)
        except Exception as e:
            self._log_line(f"[ERR] {e}"); return

        self._running = True
        self._btn.set_active(True)
        self._btn.set_text("ОТКЛЮЧИТЬ")
        self._indicator.set(True)
        self._log_line(f"Запущен: {BINARY} {ARGS}")
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
