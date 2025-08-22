#!/usr/bin/env python3
"""
WoL Webhook Server for Tailscale
--------------------------------
This script runs a simple HTTP server on port 8080 that listens for GET requests to /wake.
When triggered, it sends a Wake-on-LAN magic packet to the specified MAC address on the local network.
Intended to be run on a Raspberry Pi or Linux host as a relay for securely waking a Windows desktop via Tailscale.
"""

from http.server import BaseHTTPRequestHandler, HTTPServer
import subprocess

MAC = "c8:7f:54:6c:fa:d1"       # Desktop Intel NIC
BCAST = "192.168.20.255"        # Subnet broadcast

class H(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/wake":
            subprocess.run(["wakeonlan", "-i", BCAST, MAC], check=False)
            self.send_response(200); self.end_headers(); self.wfile.write(b"OK\n")
        else:
            self.send_response(404); self.end_headers()

if __name__ == "__main__":
    HTTPServer(("", 8080), H).serve_forever()
