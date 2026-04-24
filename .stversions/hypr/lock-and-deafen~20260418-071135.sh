#!/bin/bash

# 1. Environment Setup
export YDOTOOL_SOCKET="/run/user/1000/.ydotool_socket"

# 2. Pause any active media (Spotify, Browser, etc)
playerctl pause 2>/dev/null

# 3. Toggle Discord Deafen (Ctrl+Shift+D)
# Sends: Press Ctrl, Press Shift, Press D, Release D, Release Shift, Release Ctrl
ydotool key 29:1 42:1 32:1 32:0 42:0 29:0

# 4. Trigger the Lock Screen
hyprlock
