#!/bin/bash
SCHEME="/home/snow/.local/state/caelestia/scheme.json"
POLICY_DIR="/etc/brave/policies/managed"
POLICY_FILE="$POLICY_DIR/caelestia.json"

if [ ! -f "$SCHEME" ]; then
    echo "scheme.json not found"
    exit 1
fi

if [ ! -d "$POLICY_DIR" ]; then
    echo "Policy dir $POLICY_DIR doesn't exist. Run: sudo mkdir -p $POLICY_DIR"
    exit 1
fi

PRIMARY=$(python3 -c "
import json
with open('$SCHEME') as f:
    d = json.load(f)
print(d.get('colours', {}).get('primaryContainer', '5c386b'))
")

if [ -z "$PRIMARY" ] || [ "$PRIMARY" = "000000" ]; then
    echo "Could not read primary color"
    exit 1
fi

THEME_COLOR="#$PRIMARY"
echo "{\"BrowserThemeColor\": \"$THEME_COLOR\", \"BrowserColorScheme\": \"dark\", \"NewTabPageLocation\": \"http://localhost:8956/newtab.html\"}" | \
    sudo tee "$POLICY_FILE" > /dev/null && \
    brave --refresh-platform-policy --no-startup-window 2>/dev/null &

echo "Brave theme set to $THEME_COLOR"
