########################################################################
##  SnowDots — SnowNightlightdaemon                             Version: v1.0.0    ##
##  Last Edited: 2026-05-02                                           ##
########################################################################

#!/usr/bin/env bash

# Delete the override file on startup so reboots always follow the schedule
rm -f /tmp/night_light_manual_off

while true; do
    # If the manual override file exists, ensure hyprsunset is dead and skip
    if [ -f "/tmp/night_light_manual_off" ]; then
        pkill hyprsunset
    else
        HOUR=$(date +%H)
        if [ "$HOUR" -ge 22 ] || [ "$HOUR" -lt 5 ]; then
            pgrep -x "hyprsunset" > /dev/null || /usr/bin/hyprsunset --temperature 3000 &
        elif [ "$HOUR" -ge 18 ]; then
            pgrep -x "hyprsunset" > /dev/null || /usr/bin/hyprsunset --temperature 4500 &
        else
            /usr/bin/pkill hyprsunset
        fi
    fi
    
    sleep 30 # Check every minute so the toggle feels responsive
done
