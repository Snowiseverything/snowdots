#!/bin/bash
# OpenCode Sync — Freezer -> Snowpi
# Usage: oc-sync.sh          (full sync - configs + memory + skills)
#        oc-sync.sh --fast   (memory + dotfiles only - every 5 min)
#        oc-sync.sh --sessions (session DB only - hourly)

set -euo pipefail

SNOWPI="192.168.1.200"
SSH_USER="snow"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

case "${1:-full}" in
  --fast)
    echo "[$TIMESTAMP] Fast sync: memory + dotfiles..."
    rsync -av --delete \
      --exclude 'node_modules/' \
      --exclude 'package-lock.json' \
      "$HOME/Dotfiles/.opencode/" \
      "$SSH_USER@$SNOWPI:Dotfiles/.opencode/"
    ;;

  --sessions)
    echo "[$TIMESTAMP] Session sync: exporting + importing..."
    # Flush WAL to main DB for clean snapshot
    sqlite3 ~/.local/share/opencode/opencode.db "PRAGMA wal_checkpoint(TRUNCATE);" 2>/dev/null || true
    # Export last 50 sessions as JSON
    mkdir -p /tmp/oc-sync
    opencode export $(opencode session list 2>/dev/null | tail -50 | awk '{print $1}') \
      -o /tmp/oc-sync/sessions.json 2>/dev/null || true
    # Push to Snowpi
    rsync -av /tmp/oc-sync/sessions.json "$SSH_USER@$SNOWPI:/tmp/oc-sync/"
    # Import on Snowpi
    ssh "$SSH_USER@$SNOWPI" "cd ~ && opencode import /tmp/oc-sync/sessions.json 2>/dev/null || true" 2>/dev/null || true
    rm -f /tmp/oc-sync/sessions.json
    ;;

  full|*)
    echo "[$TIMESTAMP] Full sync: configs + dotfiles + memory + sessions..."
    # Config dir (plugins, themes, commands) — infrequent
    rsync -av --delete \
      --exclude 'node_modules/' \
      --exclude 'package-lock.json' \
      "$HOME/.config/opencode/" \
      "$SSH_USER@$SNOWPI:.config/opencode/"
    # Dotfiles .opencode (skills, AGENTS.md, SOUL.md, MEMORY.md)
    rsync -av --delete \
      --exclude 'node_modules/' \
      --exclude 'package-lock.json' \
      "$HOME/Dotfiles/.opencode/" \
      "$SSH_USER@$SNOWPI:Dotfiles/.opencode/"
    # Session DB
    sqlite3 ~/.local/share/opencode/opencode.db "PRAGMA wal_checkpoint(TRUNCATE);" 2>/dev/null || true
    rsync -av --delete ~/.local/share/opencode/opencode.db* \
      "$SSH_USER@$SNOWPI:.local/share/opencode/"
    # Rebuild node_modules on Snowpi
    echo "[$TIMESTAMP] Rebuilding node_modules on snowpi..."
    ssh "$SSH_USER@$SNOWPI" bash <<'EOF'
      set -e
      cd ~/.config/opencode && [ -f package.json ] && npm install --silent 2>/dev/null || true
      cd ~/.opencode && [ -f package.json ] && npm install --silent 2>/dev/null || true
      cd ~/Dotfiles/.opencode && [ -f package.json ] && npm install --silent 2>/dev/null || true
EOF
    ;;
esac

echo "[$TIMESTAMP] OC sync complete"
