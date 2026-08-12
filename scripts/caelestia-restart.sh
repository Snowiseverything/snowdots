#!/bin/bash
# Caelestia restart — kill ALL caelestia qs instances, clean locks, start one fresh
set -euo pipefail

QS_RUNDIR="/run/user/$(id -u)/quickshell"

# Match both `qs` and `quickshell` invocations for the caelestia config
pkill -f ' -c caelestia' 2>/dev/null || true
sleep 0.5

rm -rf "$QS_RUNDIR" 2>/dev/null
mkdir -p "$QS_RUNDIR"

qs -c caelestia -d
