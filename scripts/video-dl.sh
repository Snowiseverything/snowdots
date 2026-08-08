#!/bin/bash
########################################################################
##  SnowDots — SnowVideoDL                            Version: v2.0.0   ##
##  Download videos from 1750+ sites (YouTube, Twitter/X, Instagram,   ##
##  TikTok, Reddit, Twitch, Vimeo...) via yt-dlp.                      ##
##  v2: Ctrl+Shift+V paste hint, site detection, title confirmation,   ##
##      typo/error checking before download.                           ##
########################################################################

set -euo pipefail

DL_DIR="${VIDEO_DL_DIR:-$HOME/Downloads/Videos}"
mkdir -p "$DL_DIR"

notify() { notify-send "󰎆 SnowVideoDL" "$1" 2>/dev/null || true; }

# --- get URL ---
if [[ $# -ge 1 ]]; then
	URL="$1"
else
	URL=$(fuzzel --dmenu --lines=1 -p "Video URL: " --placeholder "Ctrl+V / Ctrl+Shift+V to paste" <<<"")
	[[ -z "$URL" ]] && exit 0
fi

# --- validate URL format (typo check) ---
if ! [[ "$URL" =~ ^https?:// ]]; then
	notify "Invalid URL — must start with http:// or https://\n$URL"
	fuzzel --dmenu --minimal-lines -p "Invalid URL — retry?" <<<$'↻ Retry\n✗ Cancel' | grep -q Retry && exec "$0"
	exit 0
fi

# --- detect site + title (error check before download) ---
INFO=$(yt-dlp --cookies-from-browser brave --simulate --no-warnings \
	--print $'%(extractor_key)s\t%(title)s\t%(duration_string)s' "$URL" 2>/dev/null | head -1) || true

if [[ -z "$INFO" || "$INFO" != *$'\t'* ]]; then
	notify "Couldn't read video info — check URL or site login\n$URL"
	fuzzel --dmenu --minimal-lines -p "No video found — retry?" <<<$'↻ Retry\n✗ Cancel' | grep -q Retry && exec "$0"
	exit 0
fi

SITE=$(cut -f1 <<<"$INFO")
TITLE=$(cut -f2 <<<"$INFO")
DUR=$(cut -f3 <<<"$INFO")
[[ "$DUR" == "NA" ]] && DUR="unknown length"

# --- confirm what we found ---
CONF=$(fuzzel --dmenu --minimal-lines -p "Download?" <<<$"Site: $SITE\nTitle: $TITLE\nLength: $DUR\n\n⬇ Download\n✗ Cancel")
[[ "$CONF" == *"Cancel"* || -z "$CONF" ]] && exit 0

# --- pick format ---
FMT=$(fuzzel --dmenu --minimal-lines -p "Format: " <<<$'Best (video+audio mp4)\nAudio only (mp3)\nBest available')
case "$FMT" in
*"Audio only"*) MODE="audio" ;;
*"Best available"*) MODE="best" ;;
*) MODE="video" ;;
esac

# --- build yt-dlp args ---
ARGS=(
	--newline
	--no-mtime
	--embed-metadata
	--cookies-from-browser brave
	-o "$DL_DIR/%(title).200B [%(id)s].%(ext)s"
	"$URL"
)

case "$MODE" in
audio) ARGS=(-x --audio-format mp3 --audio-quality 0 "${ARGS[@]}") ;;
video) ARGS=(-f "bv*+ba/b" --merge-output-format mp4 "${ARGS[@]}") ;;
best) : ;; # yt-dlp default: best quality single file
esac

# --- run ---
notify "Downloading [$SITE]: $TITLE"
if yt-dlp "${ARGS[@]}"; then
	notify "Done ✓ [$SITE] $TITLE"
else
	notify "Failed ✗ [$SITE] $TITLE"
	exit 1
fi
