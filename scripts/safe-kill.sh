#!/bin/bash
active_window=$(hyprctl activewindow -j | jq -r ".class")
if [ "$active_window" = "discord" ] || [ "$active_window" = "Brave-browser" ]; then
    xdotool key --clearmodifiers ctrl+q
else
    hyprctl dispatch killactive ""
fi
