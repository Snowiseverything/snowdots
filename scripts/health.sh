#!/bin/bash
# health.sh - Check both Freezer and Snowpi health in one shot

HOSTNAME=$(hostname)
echo "❄️  SnowHealth — both machines"
echo ""

# Local first
bash ~/scripts/snow-audit.sh | sed 's/^/  /'
echo ""

# Remote Snowpi
if command -v ssh &>/dev/null; then
    echo "── Snowpi ──────────────────────────────"
    ssh snow@192.168.1.35 'bash ~/scripts/snow-audit.sh' 2>/dev/null | sed 's/^/  /'
    echo "─────────────────────────────────────────"
fi
