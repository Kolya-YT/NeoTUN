import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox
import subprocess
import threading
import socket
import ssl
import os
import sys
import ctypes

BINARY = os.path.join(os.path.dirname(__file__), '..', 'build', 'neotun.exe')

SERVICES = [
    ("YouTube",   "www.youtube.com",   443),
    ("Discord",   "discord.com",       443),
    ("Speedtest", "www.speedtest.net", 443),
]

DEFAULT_ARGS = "-w -t -d -f 5"
TEST_TIMEOUT = 4


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
        s.settimeout(timeout)
        with ctx.wrap_socket(s, server_hostname=host) as t:
            t.sendall(f"HEAD / HTTP/1.0\r\nHost: {host}\r\n\r\n".encode())
            return len(t.recv(64)) > 0
    except Exception:
        return False


def test_all():
    results = {}
    threads = []
    def _t(name, host, _port):
        results[name] = test_host(host)
    for name, host, port in SERVICES:
        th = threading.Thread(target=_t, args=(name, host, port), daemon=True)
        th.start(); threads.append(th)
    for th in threads:
        th.join(TEST_TIMEOUT + 2)
    return results


class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("NeoTUN - DPI")
        self.resizable(False, False)
        self.process = None
        self._build_ui()

    def _build_ui(self):
        pad = {"padx": 12, "pady": 6}
        admin = is_admin()

        if not admin:
            bar = tk.Frame(self, bg="#c0392b")
            bar.grid(row=0, column=0, columnspan=2, sticky="ew")
            tk.Label(bar, text="  Нет прав администратора",
                     bg="#c0392b", fg="white", font=("Segoe UI", 9)
                     ).pack(side="left", pady=4)
            ttk.Button(bar, text="Перезапустить от администратора",
                       command=relaunch_as_admin).pack(side="right", padx=8, pady=2)

        frm = ttk.LabelFrame(self, text="Статус")
        frm.grid(row=1, column=0, columnspan=2, sticky="ew", **pad)
        frm.columnconfigure(1, weight=1)

        self.status_icon = tk.Label(frm, text="⬤", font=("Segoe UI", 16), fg="#aaa")
        self.status_icon.grid(row=0, column=0, padx=(10, 6), pady=8)

        self.status_var = tk.StringVar(value="Остановлен")
        tk.Label(frm, textvariable=self.status_var,
                 font=("Segoe UI", 11, "bold")).grid(row=0, column=1, sticky="w")

        frm_svc = ttk.LabelFrame(self, text="Сервисы")
        frm_svc.grid(row=2, column=0, columnspan=2, sticky="ew", **pad)

        self.svc_icons = {}
        self.svc_lbls = {}
        for i, (name, host, port) in enumerate(SERVICES):
            ic = tk.Label(frm_svc, text="⬤", font=("Segoe UI", 12), fg="#aaa")
            ic.grid(row=0, column=i*2, padx=(10, 2), pady=6)
            lb = tk.Label(frm_svc, text=name, font=("Segoe UI", 9), fg="#aaa")
            lb.grid(row=0, column=i*2+1, padx=(0, 12), pady=6)
            self.svc_icons[name] = ic
            self.svc_lbls[name] = lb

        self.btn_check = ttk.Button(frm_svc, text="Проверить",
                                     command=self._do_check)
        self.btn_check.grid(row=0, column=len(SERVICES)*2, padx=(4, 10), pady=4)

        self.btn_start = ttk.Button(self, text="▶  Запустить",
                                     command=self.start,
                                     state="normal" if admin else "disabled")
        self.btn_start.grid(row=3, column=0, padx=(12, 4), pady=6, sticky="ew")

        self.btn_stop = ttk.Button(self, text="■  Остановить",
                                    command=self.stop, state="disabled")
        self.btn_stop.grid(row=3, column=1, padx=(4, 12), pady=6, sticky="ew")

        self.log = scrolledtext.ScrolledText(self, height=9, width=50,
                                              state="disabled", font=("Consolas", 9))
        self.log.grid(row=4, column=0, columnspan=2, padx=12, pady=(0, 10))

        self.columnconfigure(0, weight=1)
        self.columnconfigure(1, weight=1)

    def _log(self, text):
        self.log.config(state="normal")
        self.log.insert(tk.END, text + "\n")
        self.log.see(tk.END)
        self.log.config(state="disabled")

    def _set_status(self, text, color):
        self.status_var.set(text)
        self.status_icon.config(fg=color)

    def _update_svc(self, results):
        for name, ok in results.items():
            c = "#27ae60" if ok else "#c0392b"
            if name in self.svc_icons: self.svc_icons[name].config(fg=c)
            if name in self.svc_lbls:  self.svc_lbls[name].config(fg=c)

    def _do_check(self):
        self.btn_check.config(state="disabled")
        self._log("Проверяю...")
        def _run():
            res = test_all()
            self.after(0, self._update_svc, res)
            ok  = [n for n, v in res.items() if v]
            bad = [n for n, v in res.items() if not v]
            parts = []
            if ok:  parts.append("✓ " + ", ".join(ok))
            if bad: parts.append("✗ " + ", ".join(bad))
            self.after(0, self._log, "  ".join(parts))
            self.after(0, self.btn_check.config, {"state": "normal"})
        threading.Thread(target=_run, daemon=True).start()

    def start(self):
        if not os.path.exists(BINARY):
            messagebox.showerror("Ошибка",
                f"Бинарник не найден:\n{BINARY}\n\nСобери проект через CMake.")
            return

        cmd = [BINARY] + DEFAULT_ARGS.split()
        try:
            self.process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                text=True, creationflags=subprocess.CREATE_NO_WINDOW
            )
        except Exception as e:
            messagebox.showerror("Ошибка запуска", str(e))
            return

        self.btn_start.config(state="disabled")
        self.btn_stop.config(state="normal")
        self._set_status("Работает", "#27ae60")
        self._log(f"Запущен: {' '.join(cmd)}")
        threading.Thread(target=self._read_output, daemon=True).start()

    def stop(self):
        if self.process:
            self.process.terminate()
            self.process = None
        self.btn_start.config(state="normal" if is_admin() else "disabled")
        self.btn_stop.config(state="disabled")
        self._set_status("Остановлен", "#aaa")
        for ic in self.svc_icons.values(): ic.config(fg="#aaa")
        for lb in self.svc_lbls.values():  lb.config(fg="#aaa")
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
            self.btn_start.config(state="normal" if is_admin() else "disabled")
            self.btn_stop.config(state="disabled")
            self._set_status("Остановлен", "#aaa")

    def on_close(self):
        self.stop()
        self.destroy()


if __name__ == "__main__":
    app = App()
    app.protocol("WM_DELETE_WINDOW", app.on_close)
    app.mainloop()
