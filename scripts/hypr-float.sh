########################################################################
##  SnowDots — SnowHyprfloat                             Version: v1.0.0    ##
##  Last Edited: 2026-05-02                                           ##
########################################################################

#!/bin/bash
FLOAT=$(hyprctl activewindow -j | jq -r '.floating')
if [ "$FLOAT" = "true" ]; then
    hyprctl dispatch togglefloating
else
    W=$(hyprctl activewindow -j | jq -r '.size[0]')
    H=$(hyprctl activewindow -j | jq -r '.size[1]')
    hyprctl dispatch togglefloating
    sleep 0.1
    hyprctl dispatch resizewindowpixel exact $W $H
    hyprctl dispatch centerwindow
fi
