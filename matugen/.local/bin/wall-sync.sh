#!/bin/bash
# 1. Get Path (Accept argument from skwd-wall, fallback to current.json)
WALLPAPER="${1:-$(jq -r '.path' "$HOME/.cache/skwd-wall/wallpaper/current.json" 2>/dev/null)}"
 && exit 1

# 2. Extract Colors Non-Interactively
# --source-color-index 0 prevents the interactive 'select color' prompt in Matugen v4+ [1]
RAW_JSON=$(matugen image --mode dark --type scheme-rainbow --contrast 0.6 --source-color-index 0 "$WALLPAPER" -j hex 2>/dev/null)

# 3. Parse JSON (More reliable than grep)
C1=$(echo "$RAW_JSON" | jq -r '.colors.dark.primary //.colors.dark.color1' | sed 's/#//')
C4=$(echo "$RAW_JSON" | jq -r '.colors.dark.tertiary //.colors.dark.color4' | sed 's/#//')

# 4. Final Fallback (If Matugen still fails)
[ -z "$C1" ] |

| [ "$C1" == "null" ] && C1="8839ef"
[ -z "$C4" ] |

| [ "$C4" == "null" ] && C4="cba6f7"

# 5. Live Injection into Hyprland
hyprctl keyword general:col.active_border "rgba(${C1}ff) rgba(${C4}ff) 45deg"
hyprctl keyword general:col.inactive_border "rgba(000000aa)"

# 6. Update Terminal and Notify
pkill -USR1 kitty
hyprctl notify 1 1200 "rgb($C1)" "Cyanide: Synced"
