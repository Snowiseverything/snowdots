#!/bin/bash
# Caelestia restart — kill ALL caelestia qs instances, clean locks, start one fresh
set -euo pipefail

QS_RUNDIR="/run/user/$(id -u)/quickshell"
PERSISTENT_PROPS="$QS_RUNDIR/persistent-properties.json"
TMP_BACKUP=""

# Back up persistent properties before cleanup
if [ -f "$PERSISTENT_PROPS" ]; then
	TMP_BACKUP="$(mktemp)"
	cp "$PERSISTENT_PROPS" "$TMP_BACKUP"
fi

# Match both `qs` and `quickshell` invocations for the caelestia config
pkill -f ' -c caelestia' 2>/dev/null || true
sleep 0.5

rm -rf "$QS_RUNDIR" 2>/dev/null
mkdir -p "$QS_RUNDIR"

# Restore persistent properties after cleanup
if [ -f "$TMP_BACKUP" ]; then
	cp "$TMP_BACKUP" "$PERSISTENT_PROPS"
	rm -f "$TMP_BACKUP"
fi

qs -c caelestia
