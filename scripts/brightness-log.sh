#!/bin/bash
ACTION="$1"
rm -f /tmp/brightness-cache

CURRENT=$(quickshell -c caelestia ipc call brightness getFor active 2>/dev/null)
[ -z "$CURRENT" ] && exit 1

PCT=$(printf "%.0f" "$(echo "$CURRENT * 100" | bc -l 2>/dev/null || echo 0)")

if [ "$PCT" -lt 15 ]; then STEP=2
elif [ "$PCT" -lt 35 ]; then STEP=4
elif [ "$PCT" -lt 60 ]; then STEP=6
elif [ "$PCT" -lt 85 ]; then STEP=8
else STEP=10
fi

if [ "$ACTION" = "+" ]; then
    quickshell -c caelestia ipc call brightness setFor active "+${STEP}%" 2>/dev/null
else
    quickshell -c caelestia ipc call brightness setFor active "${STEP}%-" 2>/dev/null
fi
