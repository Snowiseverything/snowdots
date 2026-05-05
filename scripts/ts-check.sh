#!/bin/bash
echo "--- [ TAILSCALE DASHBOARD SUMMARY ] ---"
echo "Hostname: $(hostname)"
echo "Tailscale IP: $(tailscale ip -4)"
echo ""
echo "--- [ ROUTING & SERVICES ] ---"
# Check for Subnet Advertising
ROUTES=$(tailscale status --json | jq -r '.Self.PrimaryRoutes // "None"')
echo "Advertised Subnets: $ROUTES"

# Check for Exit Node status
if tailscale status --json | jq -r '.Self.ExitNodeOption' | grep -q "true"; then
    echo "Exit Node: ENABLED (Offering)"
else
    echo "Exit Node: DISABLED"
fi

echo ""
echo "--- [ ACTIVE PEERS ] ---"
tailscale status | grep "active" || echo "No active peers."
