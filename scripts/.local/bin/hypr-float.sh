#!/bin/bash
# Toggles floating and ensures a "wide" default size
state=$(hyprctl activewindow -j | jq -r ".floating")

if [ "$state" = "true" ]; then
    hyprctl dispatch togglefloating 0
else
    # 1. Force the window into floating mode
    hyprctl dispatch togglefloating 1
    
    # 2. Small delay to let Hyprland catch up
    sleep 0.05
    
    # 3. Apply the wide dimensions
    hyprctl dispatch resizewindowpixel exact 1200 700
    
    # 4. Snap to center
    hyprctl dispatch centerwindow 1
fi
