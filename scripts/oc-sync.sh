#!/bin/bash
# OpenCode Sync — Bidirectional (Freezer <-> Snowpi)
# Usage: oc-sync.sh          (full sync - configs + memory + skills + sessions + projects)
#        oc-sync.sh --fast   (memory + dotfiles only - every 5 min)
#        oc-sync.sh --sessions (session DB only - bidirectional merge)
#        oc-sync.sh --projects (Projects dir only)

set -euo pipefail

SNOWPI="192.168.1.35"
SSH_USER="snow"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

case "${1:-full}" in
  --fast)
    echo "[$TIMESTAMP] Fast sync: bidirectional memory + dotfiles..."
    rsync -av --delete \
      --exclude 'node_modules/' \
      --exclude 'package-lock.json' \
      --exclude 'AGENTS.md' \
      "$SSH_USER@$SNOWPI:Dotfiles/.opencode/" \
      "$HOME/Dotfiles/.opencode/" 2>/dev/null || true
    rsync -av --delete \
      --exclude 'node_modules/' \
      --exclude 'package-lock.json' \
      --exclude 'AGENTS.md' \
      "$HOME/Dotfiles/.opencode/" \
      "$SSH_USER@$SNOWPI:Dotfiles/.opencode/"
    ;;

  --pull)
    echo "[$TIMESTAMP] Pull only: Snowpi -> Freezer..."
    rsync -av --delete \
      --exclude 'node_modules/' \
      --exclude 'package-lock.json' \
      "$SSH_USER@$SNOWPI:.config/opencode/" \
      "$HOME/.config/opencode/" 2>/dev/null || true
    rsync -av --delete \
      --exclude 'node_modules/' \
      --exclude 'package-lock.json' \
      --exclude 'AGENTS.md' \
      "$SSH_USER@$SNOWPI:Dotfiles/.opencode/" \
      "$HOME/Dotfiles/.opencode/" 2>/dev/null || true
    rsync -av --delete \
      "$SSH_USER@$SNOWPI:.agents/" \
      "$HOME/.agents/" 2>/dev/null || true
    ;;

  --sessions)
    echo "[$TIMESTAMP] Session sync: bidirectional DB merge..."
    mkdir -p /tmp/oc-sync
    set +e
    scp -q "$SSH_USER@$SNOWPI:.local/share/opencode/opencode.db" /tmp/oc-sync/snowpi.db 2>/dev/null
    if [ -f /tmp/oc-sync/snowpi.db ] && [ -s /tmp/oc-sync/snowpi.db ]; then
      # Use explicit columns to handle schema drift (metadata col may not exist on older OC)
      sqlite3 ~/.local/share/opencode/opencode.db <<SQL
        ATTACH DATABASE '/tmp/oc-sync/snowpi.db' AS snowpi;
        INSERT OR IGNORE INTO project SELECT * FROM snowpi.project;
        INSERT OR IGNORE INTO session (id, project_id, parent_id, slug, directory, title, version, share_url, summary_additions, summary_deletions, summary_files, summary_diffs, revert, permission, time_created, time_updated, time_compacting, time_archived, workspace_id, path, agent, model, cost, tokens_input, tokens_output, tokens_reasoning, tokens_cache_read, tokens_cache_write) SELECT id, project_id, parent_id, slug, directory, title, version, share_url, summary_additions, summary_deletions, summary_files, summary_diffs, revert, permission, time_created, time_updated, time_compacting, time_archived, workspace_id, path, agent, model, cost, tokens_input, tokens_output, tokens_reasoning, tokens_cache_read, tokens_cache_write FROM snowpi.session;
        INSERT OR IGNORE INTO session_message SELECT * FROM snowpi.session_message;
        INSERT OR IGNORE INTO message SELECT * FROM snowpi.message;
        INSERT OR IGNORE INTO part SELECT * FROM snowpi.part;
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

  --projects)
    echo "[$TIMESTAMP] Projects sync: Freezer -> Snowpi..."
    rsync -av --delete \
      "$HOME/Projects/" \
      "$SSH_USER@$SNOWPI:Projects/"
    ;;

  full|*)
    echo "[$TIMESTAMP] Full sync: configs + dotfiles + agents + sessions + projects..."
    # ── Pull changes from Snowpi first ──
    echo "  Pulling Snowpi -> Freezer..."
    # Pull opencode config/dotfiles/agents from Snowpi (so local changes aren't lost)
    rsync -av --delete \
      --exclude 'node_modules/' \
      --exclude 'package-lock.json' \
      "$SSH_USER@$SNOWPI:.config/opencode/" \
      "$HOME/.config/opencode/" 2>/dev/null || true
    # Exclude AGENTS.md — machine-specific identity
    rsync -av --delete \
      --exclude 'node_modules/' \
      --exclude 'package-lock.json' \
      --exclude 'AGENTS.md' \
      "$SSH_USER@$SNOWPI:Dotfiles/.opencode/" \
      "$HOME/Dotfiles/.opencode/" 2>/dev/null || true
    rsync -av --delete \
      "$SSH_USER@$SNOWPI:.agents/" \
      "$HOME/.agents/" 2>/dev/null || true
    # ── Now push Freezer -> Snowpi ──
    echo "  Pushing Freezer -> Snowpi..."
    # Config dir (plugins, themes, commands) — infrequent
    rsync -av --delete \
      --exclude 'node_modules/' \
      --exclude 'package-lock.json' \
      "$HOME/.config/opencode/" \
      "$SSH_USER@$SNOWPI:.config/opencode/"
    # Agents config — exclude AGENTS.md (machine-specific)
    rsync -av --delete \
      --exclude 'node_modules/' \
      --exclude 'package-lock.json' \
      --exclude 'AGENTS.md' \
      "$HOME/Dotfiles/.opencode/" \
      "$SSH_USER@$SNOWPI:Dotfiles/.opencode/"
    # ~/.agents/ (installed skills registry)
    rsync -av --delete \
      "$HOME/.agents/" \
      "$SSH_USER@$SNOWPI:.agents/"
    # Projects dir (Freezer -> Snowpi, create on Snowpi if missing)
    echo "  Syncing Projects -> Snowpi..."
    rsync -av --delete \
      "$HOME/Projects/" \
      "$SSH_USER@$SNOWPI:Projects/" 2>/dev/null || true
    # Sessions — bidirectional merge via SQLite
    echo "[$TIMESTAMP] Syncing sessions bidirectionally..."
    mkdir -p /tmp/oc-sync
    set +e
    scp -q "$SSH_USER@$SNOWPI:.local/share/opencode/opencode.db" /tmp/oc-sync/snowpi.db 2>/dev/null
    if [ -f /tmp/oc-sync/snowpi.db ] && [ -s /tmp/oc-sync/snowpi.db ]; then
      sqlite3 ~/.local/share/opencode/opencode.db <<SQL
        ATTACH DATABASE '/tmp/oc-sync/snowpi.db' AS snowpi;
        INSERT OR IGNORE INTO project SELECT * FROM snowpi.project;
        INSERT OR IGNORE INTO session (id, project_id, parent_id, slug, directory, title, version, share_url, summary_additions, summary_deletions, summary_files, summary_diffs, revert, permission, time_created, time_updated, time_compacting, time_archived, workspace_id, path, agent, model, cost, tokens_input, tokens_output, tokens_reasoning, tokens_cache_read, tokens_cache_write) SELECT id, project_id, parent_id, slug, directory, title, version, share_url, summary_additions, summary_deletions, summary_files, summary_diffs, revert, permission, time_created, time_updated, time_compacting, time_archived, workspace_id, path, agent, model, cost, tokens_input, tokens_output, tokens_reasoning, tokens_cache_read, tokens_cache_write FROM snowpi.session;
        INSERT OR IGNORE INTO session_message SELECT * FROM snowpi.session_message;
        INSERT OR IGNORE INTO message SELECT * FROM snowpi.message;
        INSERT OR IGNORE INTO part SELECT * FROM snowpi.part;
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
