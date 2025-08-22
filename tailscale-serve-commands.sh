#!/bin/sh
# tailscale-serve-commands.sh
# ---------------------------
# Example commands to expose the WoL webhook server securely to your Tailscale tailnet.
# Run on the relay host (e.g., Raspberry Pi) after the webhook server is running.

# Tailscale Serve setup for WoL webhook
sudo tailscale serve --bg --https=443 --set-path /wake http://127.0.0.1:8080/wake
# To map root path to wake:
# sudo tailscale serve --bg --https=443 --set-path / http://127.0.0.1:8080/wake
