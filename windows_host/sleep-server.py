#!/usr/bin/env python3
import subprocess, sys, re
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = 8765

def get_tailscale_ip():
    # 1) Try `tailscale ip -4`
    try:
        out = subprocess.check_output(["tailscale", "ip", "-4"], text=True).strip()
        ip = out.splitlines()[0].strip()
        if re.match(r"^100\.\d{1,3}\.\d{1,3}\.\d{1,3}$", ip):
            return ip
    except Exception:
        pass
    # 2) Fallback: parse ipconfig for 100.64.0.0/10 (100.x.x.x)
    try:
        out = subprocess.check_output(["ipconfig"], text=True, encoding="utf-8", errors="ignore")
        m = re.search(r"IPv4 Address[^\n]*:\s*(100\.\d{1,3}\.\d{1,3}\.\d{1,3})", out)
        if m:
            return m.group(1)
    except Exception:
        pass
    return None

TS_IP = get_tailscale_ip()
if not TS_IP:
    print("Error: could not determine Tailscale IPv4. Is Tailscale running?", file=sys.stderr)
    sys.exit(1)

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        path = self.path.lower()
        if path == "/sleep":
            # Respond immediately, then sleep after 10 seconds
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"OK\n")
            # Launch a background process to delay and then sleep
            subprocess.Popen([
                sys.executable, "-c",
                "import time,subprocess; time.sleep(10); subprocess.run(['nircmd.exe','standby'])"
            ])
        else:
            self.send_response(404); self.end_headers()

def main():
    addr = (TS_IP, PORT)
    print(f"Serving on http://{TS_IP}:{PORT}")
    HTTPServer(addr, Handler).serve_forever()

if __name__ == "__main__":
    main()
