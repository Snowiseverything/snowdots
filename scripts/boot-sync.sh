#!/bin/bash
# Boot-time orchestration — safe, non-duplicating
# Calls dotsync + oc-sync for git + rsync sync, then OC auto-fix.
set -uo pipefail

HOSTNAME=$(hostname)
LOG="$HOME/.local/share/boot-sync.log"

echo "[$(date)] === Boot Sync ($HOSTNAME) ===" | tee -a "$LOG"

# ── Wait for network ──
if ! ping -c 1 -W 2 192.168.0.1 &>/dev/null && ! ping -c 1 -W 2 gitlab.com &>/dev/null; then
    echo "[$(date)] ⚠️  No network, skipping" | tee -a "$LOG"
    exit 0
fi

# ── Git + OC session sync ──
echo "[$(date)] dotsync..." | tee -a "$LOG"
~/Dotfiles/scripts/dotsync 2>&1 | tee -a "$LOG" || echo "[$(date)] ⚠️  dotsync had issues" | tee -a "$LOG"

# ── Rsync (configs, agents, projects) ──
echo "[$(date)] oc-sync..." | tee -a "$LOG"
~/scripts/oc-sync.sh 2>&1 | tee -a "$LOG" || echo "[$(date)] ⚠️  oc-sync had issues" | tee -a "$LOG"

# ── OpenCode auto-fix git issues (60s timeout) ──
echo "[$(date)] OC check..." | tee -a "$LOG"
cd ~/Dotfiles
timeout 60 opencode run "Check this Dotfiles repo for git sync issues (diverged branches, conflicts, uncommitted changes). Fix automatically. Report what you fixed." 2>&1 | tee -a "$LOG" || echo "[$(date)] ⚠️  OC check skipped" | tee -a "$LOG"
cd ~

echo "[$(date)] === Boot Sync Complete ===" | tee -a "$LOG"
