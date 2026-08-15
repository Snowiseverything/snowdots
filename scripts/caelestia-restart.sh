#!/bin/bash
# Caelestia restart — only restart if not running or frozen
set -euo pipefail

QS_RUNDIR="/run/user/$(id -u)/quickshell"
RESTART_LOCK="$HOME/.cache/caelestia/restart.lock"

# ── Lock helpers ─────────────────────────────────────────────────────
acquire_lock() {
	local lock="$1" pid
	if [ -f "$lock" ]; then
		pid=$(cat "$lock" 2>/dev/null || true)
		if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
			return 1 # lock held by live process
		fi
	fi
	echo $$ >"$lock"
	return 0
}

release_lock() {
	rm -f "$1"
}

# ── Singleton guard ──────────────────────────────────────────────────
mkdir -p "$(dirname "$RESTART_LOCK")"
if ! acquire_lock "$RESTART_LOCK"; then
	exit 0
fi
trap 'release_lock "$RESTART_LOCK"' EXIT

# ── Helpers ──────────────────────────────────────────────────────────
notify() {
	notify-send "Caelestia" "$1" 2>/dev/null || true
}

is_responsive() {
	timeout 3 qs -c caelestia list >/dev/null 2>&1
}

# ── Main logic ───────────────────────────────────────────────────────
if ! pgrep -f ' -c caelestia' >/dev/null 2>&1; then
	notify "Starting..."
	rm -rf "$QS_RUNDIR" 2>/dev/null
	mkdir -p "$QS_RUNDIR"
	qs -c caelestia -d
	notify "Started"
	exit 0
fi

if is_responsive; then
	# Running and healthy — do nothing
	exit 0
fi

# Running but frozen — restart
notify "Restarting frozen shell..."
pkill -f ' -c caelestia' 2>/dev/null || true
sleep 0.5
rm -rf "$QS_RUNDIR" 2>/dev/null
mkdir -p "$QS_RUNDIR"
qs -c caelestia -d
notify "Restarted"
