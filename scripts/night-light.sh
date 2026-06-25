#!/usr/bin/env bash
########################################################################
##  SnowDots — Snowlight                               Version: v1.1.0  ##
##  Last Edited: 2026-05-03                                            ##
########################################################################

OVERRIDE="/tmp/night_light_manual_off"

# Fetch real sunset time for Erbil
DATA=$(curl -s "https://api.sunrise-sunset.org/json?lat=36.19&lng=44.01&formatted=0")
SUNSET_ISO=$(echo $DATA | jq -r '.results.sunset')
SUNSET_EPOCH=$(date -d "$SUNSET_ISO" +%s)
NOW_EPOCH=$(date +%s)

if [ ! -f "$OVERRIDE" ]; then
    # TURN OFF (Manual Toggle)
    touch "$OVERRIDE"
    pkill hyprsunset
    notify-send "Night Light" "Manual Override: OFF" --icon=display-brightness-symbolic
else
    # TURN ON / RESUME
    rm "$OVERRIDE"
    
    # Logic: If current time is past sunset, turn it on
    if [ "$NOW_EPOCH" -ge "$SUNSET_EPOCH" ]; then
        # Late night (after 10 PM) gets warmer
        if [ "$(date +%H)" -ge 22 ]; then TEMP=3000; else TEMP=4500; fi
        
        hyprsunset --temperature $TEMP &
        notify-send "Night Light" "Sun has set. Auto-Schedule: ON" --icon=display-brightness-symbolic
    else
        notify-send "Night Light" "Resumed (Waiting for sunset)" --icon=display-brightness-symbolic
    fi
fi
