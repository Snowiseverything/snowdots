#!/bin/bash
ACTION="$1"
CURRENT=$(ddcutil getvcp 10 2>/dev/null | grep -oP 'current value =\s+\K\d+')
[ -z "$CURRENT" ] && exit 1

if [ "$CURRENT" -lt 15 ]; then STEP=2
elif [ "$CURRENT" -lt 35 ]; then STEP=4
elif [ "$CURRENT" -lt 60 ]; then STEP=6
elif [ "$CURRENT" -lt 85 ]; then STEP=8
else STEP=10
fi

ddcutil setvcp 10 $ACTION $STEP 2>/dev/null
