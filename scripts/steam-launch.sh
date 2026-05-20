#!/bin/bash
# Steam launcher wrapper — fixes XWayland CEF crash on Wayland
export STEAM_FORCE=1
exec steam "$@"
