#!/bin/bash
# Apply matugen palette to running forkgram via Wayland keyboard automation
# Uses wtype + hyprctl to simulate the GUI import flow
#  1. Focus forkgram → Ctrl+, (Settings) → type "import" → Tab 12x → Enter
#  2. File dialog opens → type path → Enter

PALETTE_FILE="${1:-$HOME/.cache/skwd-wall/forkgram.tdesktop-palette}"
LOG_FILE="/tmp/forkgram-palette.log"

log() { echo "[$(date '+%H:%M:%S')] $1" >>"$LOG_FILE"; }

log "=== Forkgram palette import ==="
log "Palette: $PALETTE_FILE"

# Wait for forkgram window to exist
for i in {1..10}; do
	WINDOW_OK=$(hyprctl clients -j 2>/dev/null | python3 -c "
import json,sys
try:
    clients=json.load(sys.stdin)
    for c in clients:
        if 'forkgram' in c.get('class','').lower():
            print(1)
            sys.exit(0)
except: pass
print(0)
")
	if [ "$WINDOW_OK" = "1" ]; then break; fi
	sleep 0.5
done

if [ "$WINDOW_OK" != "1" ]; then
	log "ERROR: forkgram window not found"
	exit 1
fi

# Focus forkgram
hyprctl dispatch 'hl.dsp.focus({ window = "class:forkgram" })' 2>/dev/null
sleep 0.5

# Open Settings
log "Opening Settings..."
wtype -M ctrl -k comma -m ctrl
sleep 1.5

# Search field should be focused — type "import" to filter
log "Searching for import..."
wtype -s 0.05 "import"
sleep 0.8

# Tab to reach "Import a palette" button
# The number of tabs depends on widget layout, 12 should cover most cases
log "Navigating to Import button..."
for i in {1..12}; do
	wtype -k Tab
	sleep 0.12
done

# Press Enter to trigger import (opens file dialog)
wtype -k Return
sleep 1.5

# File dialog should be open now
# Type the palette file path
log "Typing palette path..."
wtype -s 0.03 "$PALETTE_FILE"
sleep 0.5

# Press Enter to import
wtype -k Return
sleep 1

# Close Settings
wtype -k Escape
sleep 0.2

log "Palette import sequence completed"
