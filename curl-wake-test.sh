#!/bin/sh
# curl-wake-test.sh
# -----------------
# Script to test the WoL webhook server locally and via Tailscale HTTPS endpoint.
# Use this to verify the relay and Tailscale serve setup.

# Test the WoL webhook locally
curl http://127.0.0.1:8080/wake
# Test via Tailscale HTTPS endpoint (replace <tailnet> as needed)
curl https://private-vlan-hp.<tailnet>.ts.net/wake
