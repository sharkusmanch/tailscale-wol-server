#!/usr/bin/env python3
from http.server import BaseHTTPRequestHandler, HTTPServer
import subprocess, urllib.request

MAC   = "c8:7f:54:6c:fa:d1"          # Windows onboard NIC MAC (for WoL)
BCAST = "192.168.20.255"             # VLAN20 broadcast
SLEEP_URL = "http://100.118.228.32:8765/sleep"  # Windows Tailscale IP + sleep API

class H(BaseHTTPRequestHandler):
    def do_GET(self):
        p = self.path.lower()
        if p == "/wake":
            subprocess.run(["wakeonlan", "-i", BCAST, MAC], check=False)
            self._ok(b"OK\n")
        elif p == "/sleep":
            try:
                with urllib.request.urlopen(SLEEP_URL, timeout=5) as r:
                    _ = r.read()
                self._ok(b"SLEEP\n")
            except Exception:
                self.send_response(502); self.end_headers()
        else:
            self.send_response(404); self.end_headers()

    def _ok(self, body):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(body)

if __name__ == "__main__":
    HTTPServer(("", 8080), H).serve_forever()
