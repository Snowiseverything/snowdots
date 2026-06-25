#!/bin/bash
# health.sh - Quick health overview: local + Snowpi

SNOWPI="192.168.1.35"
TIMEOUT=5

echo "❄️  SnowHealth"
echo ""

# ── Local ──
echo "  ── freezer ──"
echo "    Uptime  : $(uptime -p | sed 's/up //')"
echo "    CPU Temp: $(( $(cat /sys/class/thermal/thermal_zone1/temp 2>/dev/null || echo 0) / 1000 ))°C"
echo "    Disk    : $(df -h / | awk 'NR==2{print $3"/"$2" ("$5")"}')"
echo "    Memory  : $(free -h | awk '/Mem/{print $3"/"$2}')"
echo "    Docker  : $(docker ps -q 2>/dev/null | wc -l) container(s)"
echo ""

# ── Snowpi ──
echo "  ── snowpi ──"
if ssh -o ConnectTimeout=$TIMEOUT -o BatchMode=yes snow@$SNOWPI "echo ok" 2>/dev/null; then
    ssh -o ConnectTimeout=$TIMEOUT snow@$SNOWPI "
        echo '    Uptime  : '\$(uptime -p | sed 's/up //')
        echo '    CPU Temp: '\$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | head -1 | awk '{print \$1/1000\"°C\"}')
        echo '    Disk    : '\$(df -h / | awk 'NR==2{print \$3\"/\"\$2\" (\"\$5\")\"}')
        echo '    Memory  : '\$(free -h | awk '/Mem/{print \$3\"/\"\$2}')
    "
else
    echo "    ⚠ offline (timeout)"
fi
echo ""
