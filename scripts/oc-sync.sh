#!/bin/bash
# OpenCode Sync — Freezer -> Snowpi
# Usage: oc-sync.sh          (full sync - configs + memory + skills)
#        oc-sync.sh --fast   (memory + dotfiles only - every 5 min)
#        oc-sync.sh --sessions (disabled - version mismatch)

set -euo pipefail

SNOWPI="100.83.33.67"
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
    echo "[$TIMESTAMP] Session sync disabled — version mismatch Freezer 1.15.7 vs Snowpi 1.15.12"
    echo "  Re-enable by running: upgrade opencode on Freezer to match Snowpi"
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
    ;;
esac

echo "[$TIMESTAMP] OC sync complete"
