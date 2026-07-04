#!/bin/bash
# Boot-time orchestration — safe, failure-resistant
set -uo pipefail

HOSTNAME=$(hostname)
LOG="$HOME/.local/share/boot-sync.log"
STATE="$HOME/.local/state/boot-sync"
SKIP_FILE="$STATE/skip"
FAIL_FILE="$STATE/failures"

mkdir -p "$STATE"

# ── Force-skip if flag file exists ──
if [ -f "$SKIP_FILE" ]; then
  echo "[$(date)] === Boot Sync ($HOSTNAME) SKIPPED (skip file present) ===" >> "$LOG"
  exit 0
fi

# ── Auto-skip after 3 consecutive failures ──
FAIL_COUNT=0
[ -f "$FAIL_FILE" ] && FAIL_COUNT=$(cat "$FAIL_FILE")
if [ "$FAIL_COUNT" -ge 3 ]; then
  echo "[$(date)] === Boot Sync ($HOSTNAME) SKIPPED ($FAIL_COUNT consecutive failures) ===" >> "$LOG"
  exit 0
fi

echo "[$(date)] === Boot Sync ($HOSTNAME) ===" | tee -a "$LOG"

# ── Quick network check (2s total) ──
if ! ping -c 1 -W 1 192.168.0.1 &>/dev/null && ! ping -c 1 -W 1 100.83.33.67 &>/dev/null; then
  echo "[$(date)] ⚠️  No network, skipping" | tee -a "$LOG"
  exit 0
fi

FAILED=0

# ── Git sync (60s timeout) ──
echo "[$(date)] dotsync..." | tee -a "$LOG"
timeout 60 ~/Dotfiles/scripts/dotsync 2>&1 | tee -a "$LOG" || { echo "[$(date)] ⚠️  dotsync failed/timed out" | tee -a "$LOG"; FAILED=1; }

# ── Rsync session DB to Snowpi (120s timeout) ──
echo "[$(date)] session-db..." | tee -a "$LOG"
timeout 120 rsync --partial --append-verify -avz \
  "$HOME/.local/share/opencode/opencode.db" \
  snow@100.83.33.67:/home/snow/.local/share/opencode/opencode.db.freezer-backup \
  2>&1 | tee -a "$LOG" || { echo "[$(date)] ⚠️  session-db rsync failed/timed out" | tee -a "$LOG"; FAILED=1; }

# ── Track failures ──
if [ "$FAILED" -eq 1 ]; then
  echo $((FAIL_COUNT + 1)) > "$FAIL_FILE"
else
  rm -f "$FAIL_FILE"
fi

echo "[$(date)] === Boot Sync Complete ($([ "$FAILED" -eq 1 ] && echo 'with errors' || echo 'ok')) ===" | tee -a "$LOG"
