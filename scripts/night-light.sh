########################################################################
##  SnowDots — Snowlight                             Version: v1.0.0    ##
##  Last Edited: 2026-05-02                                           ##
########################################################################

#!/usr/bin/env bash

OVERRIDE="/tmp/night_light_manual_off"

if [ ! -f "$OVERRIDE" ]; then
    # TURN OFF
    touch "$OVERRIDE"
    pkill hyprsunset
    notify-send "Night Light" "Manual Override: OFF (Reset on Reboot)" --icon=display-brightness-symbolic
else
    # TURN ON
    rm "$OVERRIDE"
    
    # Instant Re-enable: Calculate temp right now so we don't wait for the daemon
    HOUR=$(date +%H)
    if [ "$HOUR" -ge 22 ] || [ "$HOUR" -lt 5 ]; then
        TEMP=3000
    elif [ "$HOUR" -ge 18 ]; then
        TEMP=4500
    else
        TEMP=6000
    fi

    # Only start if it's actually evening/night time
    if [ "$HOUR" -ge 18 ] || [ "$HOUR" -lt 5 ]; then
        hyprsunset --temperature $TEMP &
    fi

    notify-send "Night Light" "Auto-Schedule: RESUMED" --icon=display-brightness-symbolic
fi
