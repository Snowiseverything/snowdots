#!/bin/bash
########################################################################
##  SnowDots — SnowVideoDL Server                     Version: v1.0.0   ##
##  Local yt-dlp download server for the Video Downloader userscript.  ##
##  Listens on 127.0.0.1:8765, accepts {url} POSTs, runs yt-dlp.       ##
########################################################################

set -euo pipefail

PORT="${VIDEO_DL_PORT:-8765}"
DL_DIR="${VIDEO_DL_DIR:-$HOME/Downloads/Videos}"
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/video-dl-server.pid"
LOGFILE="${XDG_RUNTIME_DIR:-/tmp}/video-dl-server.log"
SERVER="$HOME/.local/bin/video-dl-server.py"

start() {
	[[ -f "$PIDFILE" ]] && kill -0 "$(head -1 "$PIDFILE")" 2>/dev/null && {
		echo "already running (pid $(cat "$PIDFILE"))"
		return 0
	}
	rm -f "$PIDFILE"
	VIDEO_DL_PORT="$PORT" VIDEO_DL_DIR="$DL_DIR" setsid nohup "$SERVER" >"$LOGFILE" 2>&1 &
	echo $! >"$PIDFILE"
	echo "$DL_DIR" >>"$PIDFILE"
	sleep 1
	kill -0 "$(head -1 "$PIDFILE")" 2>/dev/null && echo "server started (pid $(head -1 "$PIDFILE"), port $PORT, dir $DL_DIR)" ||
		{
			echo "FAILED to start — log:"
			cat "$LOGFILE"
			rm -f "$PIDFILE"
			return 1
		}
}

stop() {
	[[ -f "$PIDFILE" ]] || {
		echo "not running"
		return 0
	}
	kill "$(head -1 "$PIDFILE")" 2>/dev/null
	rm -f "$PIDFILE"
	echo "stopped"
}

status() {
	if [[ -f "$PIDFILE" ]] && kill -0 "$(head -1 "$PIDFILE")" 2>/dev/null; then
		PID=$(head -1 "$PIDFILE")
		DIR=$(tail -1 "$PIDFILE")
		echo "running (pid $PID, port $PORT, dir $DIR)"
	else
		echo "not running"
	fi
}

case "${1:-}" in
start) start ;;
stop) stop ;;
status | stat) status ;;
*) echo "usage: $0 {start|stop|status}" ;;
esac
