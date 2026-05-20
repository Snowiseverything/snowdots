#!/bin/bash
if [ -f /tmp/volume-unlimited ]; then
    rm /tmp/volume-unlimited
    notify-send "Volume" "Limited to 100%" -t 1500
else
    touch /tmp/volume-unlimited
    notify-send "Volume" "Unlimited (up to 150%)" -t 1500
fi
