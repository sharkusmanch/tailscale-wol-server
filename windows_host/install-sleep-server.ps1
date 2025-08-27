# install-sleep-server.ps1
param(
  [ValidateSet('install','uninstall')]
  [string]$action = 'install',
  [string]$ServiceName = 'SleepServer',
  [int]$Port = 8765
)

$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$PyFile = Join-Path $Here 'sleep-server.py'
$LogOut = Join-Path $Here 'sleep-server.out.log'
$LogErr = Join-Path $Here 'sleep-server.err.log'

function Find-Exe($name, $altPaths) {
  $cmd = (Get-Command $name -ErrorAction SilentlyContinue)?.Source
  if ($cmd) { return $cmd }
  foreach ($p in $altPaths) { if (Test-Path $p) { return $p } }
  throw "Missing executable: $name. Put it on PATH or next to this script."
}

# Locate tools
$Nssm = Find-Exe 'nssm.exe' @((Join-Path $Here 'nssm.exe'))
# Prefer python.exe; fall back to py.exe
$Python = (Get-Command python.exe -ErrorAction SilentlyContinue)?.Source
if (-not $Python) { $Python = Find-Exe 'py.exe' @() }

if ($action -eq 'uninstall') {
  try { & $Nssm stop $ServiceName | Out-Null } catch {}
  try { & $Nssm remove $ServiceName confirm | Out-Null } catch {}
  # Remove firewall rule
  Get-NetFirewallRule -DisplayName "Sleep API ($ServiceName)" -ErrorAction SilentlyContinue | Remove-NetFirewallRule
  Write-Host "Uninstalled $ServiceName."
  exit 0
}

# Write sleep-server.py (binds to Tailscale IPv4 at runtime)
$pySrc = @"
#!/usr/bin/env python3
import subprocess, sys, re
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = $Port

def get_tailscale_ip():
    try:
        out = subprocess.check_output(["tailscale","ip","-4"], text=True).strip()
        ip = out.splitlines()[0].strip()
        if re.match(r"^100\.\d{1,3}\.\d{1,3}\.\d{1,3}$", ip): return ip
    except Exception:
        pass
    try:
        out = subprocess.check_output(["ipconfig"], text=True, encoding="utf-8", errors="ignore")
        m = re.search(r"IPv4 Address[^\n]*:\s*(100\.\d{1,3}\.\d{1,3}\.\d{1,3})", out)
        if m: return m.group(1)
    except Exception:
        pass
    return None

TS_IP = get_tailscale_ip()
if not TS_IP:
    print("Error: no Tailscale IPv4 found. Is Tailscale running?", file=sys.stderr)
    sys.exit(1)

class H(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.lower() == "/sleep":
            subprocess.run(["powershell.exe","-NoProfile","-Command","Suspend-Computer -Force"], check=False)
            self.send_response(200); self.end_headers(); self.wfile.write(b"OK\\n")
        else:
            self.send_response(404); self.end_headers()

def main():
    addr = (TS_IP, PORT)
    print(f"Serving on http://{TS_IP}:{PORT}")
    HTTPServer(addr, H).serve_forever()

if __name__ == "__main__":
    main()
"@
Set-Content -Path $PyFile -Value $pySrc -Encoding UTF8 -NoNewline

# Build NSSM service
$App = $Python
$Args = if ($Python -like '*py.exe') { "$PyFile" } else { $PyFile }

# Create or update service
& $Nssm install $ServiceName $App $Args | Out-Null
& $Nssm set $ServiceName AppDirectory $Here | Out-Null
& $Nssm set $ServiceName AppStdout $LogOut | Out-Null
& $Nssm set $ServiceName AppStderr $LogErr | Out-Null
& $Nssm set $ServiceName Start SERVICE_AUTO_START | Out-Null
& $Nssm set $ServiceName AppRestartDelay 5000 | Out-Null

# Start service
& $Nssm stop $ServiceName | Out-Null 2>$null
& $Nssm start $ServiceName | Out-Null

# Lock down firewall to tailnet (100.64.0.0/10). Narrow to your Pi if desired.
$ruleName = "Sleep API ($ServiceName)"
Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue | Remove-NetFirewallRule | Out-Null
New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Protocol TCP -LocalPort $Port -RemoteAddress 100.64.0.0/10 -Action Allow | Out-Null

Write-Host "Service $ServiceName installed and started."
Write-Host "Test:  curl http://$(tailscale ip -4 | Select-Object -First 1):$Port/sleep"
