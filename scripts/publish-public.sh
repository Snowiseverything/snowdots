#!/bin/bash
# publish-public.sh - Strip personal info, push sanitized copy to GitHub
# Called optionally after dotsync. Asks before pushing.

set -e

REPO_SOURCE="$HOME/Dotfiles"
TEMP_DIR=$(mktemp -d)
GH_REMOTE="git@github.com:Snowiseverything/snowdots.git"

cleanup() { rm -rf "$TEMP_DIR"; }
trap cleanup EXIT

echo "📦 Cloning repo to temp..."
git clone "$REPO_SOURCE" "$TEMP_DIR/snowdots" 2>/dev/null
cd "$TEMP_DIR/snowdots"

echo "🧹 Scrubbing personal info..."

# Remove opencode config (has IPs, hostnames, memory)
rm -rf .opencode/

# Remove SSH dir (keys, config)
rm -rf .ssh/

# Replace specific IPs with placeholders
find . -type f \( -name '*.sh' -o -name '*.fish' -o -name '*.conf' -o -name '*.md' -o -name '*.toml' \) \
  -exec sed -i \
    -e 's/192\.168\.0\.111/192.168.1.100/g' \
    -e 's/192\.168\.1\.35/192.168.1.200/g' \
    {} +

# Commit and push
git add -A
git diff --cached --quiet && echo "⏭️  No changes to publish" && exit 0

echo "📦 Committing sanitized version..."
git commit -m "sync | public | $(date +%F)"

echo "🚀 Force-pushing to GitHub..."
git push "$GH_REMOTE" main --force 2>/dev/null || echo "⚠️  Push failed"
