#!/bin/bash
ACTION="$1"
SINK="@DEFAULT_AUDIO_SINK@"
CURRENT=$(wpctl get-volume $SINK | awk '{print int($2 * 100)}')

if [ "$CURRENT" -lt 15 ]; then STEP=2
elif [ "$CURRENT" -lt 35 ]; then STEP=4
elif [ "$CURRENT" -lt 60 ]; then STEP=6
elif [ "$CURRENT" -lt 85 ]; then STEP=8
else STEP=10
fi

wpctl set-volume $SINK ${STEP}%${ACTION}
