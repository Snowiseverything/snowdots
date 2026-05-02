########################################################################
##  SnowDots — SnowSafekill                             Version: v1.0.0    ##
##  Last Edited: 2026-05-02                                           ##
########################################################################

#!/bin/bash
active_window=$(hyprctl activewindow -j | jq -r ".class")
if [ "$active_window" = "discord" ] || [ "$active_window" = "Brave-browser" ]; then
    xdotool key --clearmodifiers ctrl+q
else
    hyprctl dispatch killactive ""
fi
