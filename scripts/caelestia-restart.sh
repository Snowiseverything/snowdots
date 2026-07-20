#!/bin/bash
# Caelestia restart — kill ALL qs instances, clean locks, start one fresh
QS_RUNDIR="/run/user/$(id -u)/quickshell"

PIDS=$(pgrep -x "qs" 2>/dev/null)
if [ -n "$PIDS" ]; then
    kill -TERM $PIDS 2>/dev/null
    sleep 0.3
    PIDS=$(pgrep -x "qs" 2>/dev/null)
    if [ -n "$PIDS" ]; then
        kill -KILL $PIDS 2>/dev/null
        sleep 0.3
    fi
fi

rm -rf "$QS_RUNDIR" 2>/dev/null
mkdir -p "$QS_RUNDIR"

qs -c caelestia -d
