#!/bin/bash
########################################################################
##  SnowDots — Force Kill (frozen app/game)         Version: v1.3.0    ##
##  Kills the focused window's full process tree.                     ##
##  Confirms via notification action buttons, then SIGTERM → SIGKILL. ##
########################################################################

# Get focused window PID + class
read -r WINDOW_PID WINDOW_CLASS <<<"$(hyprctl activewindow -j 2>/dev/null | jq -r '[.pid, .class] | @tsv')"

if [ -z "$WINDOW_PID" ] || [ "$WINDOW_PID" = "null" ] || [ "$WINDOW_PID" -le 1 ]; then
	notify-send -u critical "Force Kill" "No valid focused window"
	exit 1
fi

# Never kill the compositor or session-critical processes
case "$WINDOW_CLASS" in
Hyprland | wayfire | sway)
	notify-send -u critical "Force Kill" "Refusing to kill $WINDOW_CLASS"
	exit 1
	;;
esac

# Build the full process tree (root pid + all descendants)
PIDS=("$WINDOW_PID")
collect_children() {
	local parent="$1"
	for child in $(pgrep -P "$parent" 2>/dev/null); do
		PIDS+=("$child")
		collect_children "$child"
	done
}
collect_children "$WINDOW_PID"

# Confirm via zenity alert window (protects working apps)
if ! zenity --question --title="Force Kill" \
	--text="Force kill $WINDOW_CLASS?\n\nPID $WINDOW_PID, ${#PIDS[@]} processes" \
	--ok-label="Kill" --cancel-label="Cancel" 2>/dev/null; then
	exit 1
fi

# Reverse so children die first, then parent
for ((i = ${#PIDS[@]} - 1; i >= 0; i--)); do
	kill -TERM "${PIDS[$i]}" 2>/dev/null
done

notify-send -u normal "Force Kill" "SIGTERM sent to $WINDOW_CLASS (${#PIDS[@]} processes)"

# Escalate to SIGKILL after 3s if anything still alive
sleep 3
for pid in "${PIDS[@]}"; do
	if kill -0 "$pid" 2>/dev/null; then
		kill -KILL "$pid" 2>/dev/null
	fi
done
