#!/bin/bash
ACTION="$1"
SINK="@DEFAULT_AUDIO_SINK@"
LIMIT=""

if [ ! -f /tmp/volume-unlimited ]; then
    LIMIT="--limit 1.0"
fi

wpctl set-volume $LIMIT $SINK 2%${ACTION}
