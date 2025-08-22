# Wake-on-LAN Over Tailscale Setup

This document describes how to set up a Raspberry Pi as a Wake-on-LAN (WoL) relay host, expose a secure HTTPS endpoint inside a Tailscale tailnet, and configure a Windows 11 desktop to wake on demand.

---

## 1. Host Information
- **WoL Relay**: Raspberry Pi 4, Debian 12
  - Hostname: `private-vlan-hp`
  - IP (DHCP): `192.168.20.x`
- **Target Desktop**: Windows 11
  - IP: `192.168.20.90`
  - WoL NIC (Intel onboard): `C8:7F:54:6C:FA:D1`
  - 10GbE card (ASUS XG-C100C) does **not** support WoL

---

## 2. Raspberry Pi Setup


### Install packages
See instructions below. Scripts and configs are now in their own files in the repo.

1. Update and install dependencies:
  sudo apt update
  sudo apt install -y python3 wakeonlan tailscale
  sudo tailscale up --ssh


### Webhook script
See [`opt/wol/wol-server.py`](opt/wol/wol-server.py) for the Python webhook server.
Make it executable:
  sudo chmod +x /opt/wol/wol-server.py


### Systemd unit
See [`etc/systemd/system/wol-server.service`](etc/systemd/system/wol-server.service) for the systemd service file.


Enable service:
  sudo systemctl daemon-reload
  sudo systemctl enable --now wol-server


Check:
See [`curl-wake-test.sh`](curl-wake-test.sh) for a test script.

---

## 3. Tailscale Serve (Tailnet Only)


### Configure serve
See [`tailscale-serve-commands.sh`](tailscale-serve-commands.sh) for Tailscale serve commands.

### Verify
```sh
tailscale serve status
```
Expected:
```
https://private-vlan-hp.<tailnet>.ts.net/wake
|-- proxy http://127.0.0.1:8080/wake
```

### Usage
- From any tailnet device:
  See [`curl-wake-test.sh`](curl-wake-test.sh) for example usage.
- Returns `OK` and sends WoL magic packet.

---

## 4. Windows 11 Desktop Configuration

### BIOS/UEFI
1. Enter **Advanced Mode (F7)**.
2. Navigate: **Advanced → APM Configuration**.
3. Enable **Power On By PCI-E/PCI**.
4. Save & Exit.

### Windows NIC settings
1. Device Manager → Intel Ethernet → Properties.
2. **Advanced tab**:
   - Enable *Wake on Magic Packet*.
3. **Power Management tab**:
   - ✔ Allow this device to wake the computer
   - ✔ Only allow a magic packet to wake the computer

### IP & MAC
- Confirmed WoL NIC: `C8-7F-54-6C-FA-D1` (onboard Intel).
- ASUS XG-C100C (`FC-34-97-28-3E-FA`) does not support WoL.

### Network metrics

Ensure 10GbE NIC stays primary:
See [`windows-nic-metric.ps1`](windows-nic-metric.ps1) for a PowerShell script to set interface metrics.

---

## 5. iPhone Integration

### Requirements
- Tailscale iOS app installed and connected to tailnet.

### Shortcut setup
1. Open **Shortcuts** app.
2. New Shortcut → Action: *Open URL*.
3. URL:
   ```
   https://private-vlan-hp.<tailnet>.ts.net/wake
   ```
4. Save as “Wake Gaming PC”.
5. Optional: add to Home Screen or Siri voice trigger.

---

## 6. Optional Tweaks

- **No lock screen on wake**:
  - Settings → Accounts → Sign-in Options → *If you’ve been away…* → **Never**.
- **Root mapping** (so `/` triggers wake):

  See [`tailscale-serve-commands.sh`](tailscale-serve-commands.sh) for the root mapping command.

---

## 7. Test Procedure

1. Put desktop into Sleep.
2. On iPhone, run Shortcut “Wake Gaming PC”.
3. Pi sends WoL → Desktop powers on.

---

## 8. Summary

- Raspberry Pi acts as WoL relay.
- Exposed securely to tailnet with `tailscale serve`.
- Desktop wakes via onboard Intel NIC.
- One-tap wake from iPhone using Shortcuts + Tailscale.
