#!/bin/bash
# OpenCode Sync — Freezer -> Snowpi
# Usage: oc-sync.sh          (full sync - configs + memory + skills + sessions)
#        oc-sync.sh --fast   (memory + dotfiles only - every 5 min)
#        oc-sync.sh --sessions (session DB only - bidirectional merge)

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
    echo "[$TIMESTAMP] Session sync: bidirectional DB merge..."
    mkdir -p /tmp/oc-sync
    set +e
    scp -q "$SSH_USER@$SNOWPI:.local/share/opencode/opencode.db" /tmp/oc-sync/snowpi.db 2>/dev/null
    if [ -f /tmp/oc-sync/snowpi.db ] && [ -s /tmp/oc-sync/snowpi.db ]; then
      sqlite3 ~/.local/share/opencode/opencode.db <<SQL
        ATTACH DATABASE '/tmp/oc-sync/snowpi.db' AS snowpi;
        INSERT OR IGNORE INTO project SELECT * FROM snowpi.project;
        INSERT OR IGNORE INTO session SELECT * FROM snowpi.session;
        INSERT OR IGNORE INTO session_message SELECT * FROM snowpi.session_message;
        INSERT OR IGNORE INTO message SELECT * FROM snowpi.message;
        INSERT OR IGNORE INTO todo SELECT * FROM snowpi.todo;
        DETACH snowpi;
SQL
      echo "  Merged $(sqlite3 /tmp/oc-sync/snowpi.db 'SELECT COUNT(*) FROM session') Snowpi sessions"
    fi
    sqlite3 ~/.local/share/opencode/opencode.db "PRAGMA wal_checkpoint(TRUNCATE);" 2>/dev/null || true
    rsync -av --delete ~/.local/share/opencode/opencode.db* \
      "$SSH_USER@$SNOWPI:.local/share/opencode/"
    rm -rf /tmp/oc-sync
    set -e
    ;;

  full|*)
    echo "[$TIMESTAMP] Full sync: configs + dotfiles + agents + sessions..."
    # Config dir (plugins, themes, commands) — infrequent
    rsync -av --delete \
      --exclude 'node_modules/' \
      --exclude 'package-lock.json' \
      "$HOME/.config/opencode/" \
      "$SSH_USER@$SNOWPI:.config/opencode/"
    # Agents config (skills, AGENTS.md, SOUL.md, MEMORY.md, agents/)
    rsync -av --delete \
      --exclude 'node_modules/' \
      --exclude 'package-lock.json' \
      "$HOME/Dotfiles/.opencode/" \
      "$SSH_USER@$SNOWPI:Dotfiles/.opencode/"
    # ~/.agents/ (installed skills registry)
    rsync -av --delete \
      "$HOME/.agents/" \
      "$SSH_USER@$SNOWPI:.agents/"
    # Sessions — bidirectional merge via SQLite
    echo "[$TIMESTAMP] Syncing sessions bidirectionally..."
    mkdir -p /tmp/oc-sync
    set +e
    scp -q "$SSH_USER@$SNOWPI:.local/share/opencode/opencode.db" /tmp/oc-sync/snowpi.db 2>/dev/null
    if [ -f /tmp/oc-sync/snowpi.db ] && [ -s /tmp/oc-sync/snowpi.db ]; then
      sqlite3 ~/.local/share/opencode/opencode.db <<SQL
        ATTACH DATABASE '/tmp/oc-sync/snowpi.db' AS snowpi;
        INSERT OR IGNORE INTO project SELECT * FROM snowpi.project;
        INSERT OR IGNORE INTO session SELECT * FROM snowpi.session;
        INSERT OR IGNORE INTO session_message SELECT * FROM snowpi.session_message;
        INSERT OR IGNORE INTO message SELECT * FROM snowpi.message;
        INSERT OR IGNORE INTO todo SELECT * FROM snowpi.todo;
        DETACH snowpi;
SQL
      echo "  Merged $(sqlite3 /tmp/oc-sync/snowpi.db 'SELECT COUNT(*) FROM session') Snowpi sessions"
    fi
    sqlite3 ~/.local/share/opencode/opencode.db "PRAGMA wal_checkpoint(TRUNCATE);" 2>/dev/null || true
    rsync -av --delete ~/.local/share/opencode/opencode.db* \
      "$SSH_USER@$SNOWPI:.local/share/opencode/"
    rm -rf /tmp/oc-sync
    set -e
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
