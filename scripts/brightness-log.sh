#!/bin/bash
CACHE="/tmp/brightness-cache"
ACTION="$1"

if [ -f "$CACHE" ]; then
    CURRENT=$(cat "$CACHE")
else
    CURRENT=$(ddcutil getvcp 10 2>/dev/null | grep -oP 'current value =\s+\K\d+')
    [ -z "$CURRENT" ] && exit 1
fi

if [ "$CURRENT" -lt 15 ]; then STEP=2
elif [ "$CURRENT" -lt 35 ]; then STEP=4
elif [ "$CURRENT" -lt 60 ]; then STEP=6
elif [ "$CURRENT" -lt 85 ]; then STEP=8
else STEP=10
fi

NEXT=$((CURRENT $ACTION STEP))
[ "$NEXT" -lt 0 ] && NEXT=0
[ "$NEXT" -gt 100 ] && NEXT=100
echo "$NEXT" > "$CACHE"

ddcutil setvcp 10 $ACTION $STEP 2>/dev/null &
