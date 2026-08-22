#!/bin/bash
# SnowHyprfloat — toggle active window floating with cascade (serpantinum-compatible).
# Uses standard hyprctl dispatchers (no caelestia hl.dsp).
set -euo pipefail

# Is the active window floating?
FLOAT=$(hyprctl activewindow -j 2>/dev/null | jq -r '.floating // "false"')

if [ "$FLOAT" == "true" ]; then
    # un-float, return to tiling
    hyprctl dispatch togglefloating >/dev/null 2>&1
else
    WS=$(hyprctl activewindow -j 2>/dev/null | jq -r '.workspace.id // 0')
    FLOAT_COUNT=$(hyprctl clients -j 2>/dev/null | jq "[.[] | select(.workspace.id == $WS and .floating == true)] | length" 2>/dev/null || echo 0)
    CASCADE=$((FLOAT_COUNT * 40))

    hyprctl dispatch togglefloating >/dev/null 2>&1 # float
    hyprctl dispatch centerwindow >/dev/null 2>&1   # center
    if [ "$CASCADE" -gt 0 ]; then
        # nudge by cascade offset (moveactivetoworkspace won't do; use movewindow by px)
        hyprctl dispatch movewindow m "$CASCADE" "$CASCADE" >/dev/null 2>&1 || true
    fi
fi
