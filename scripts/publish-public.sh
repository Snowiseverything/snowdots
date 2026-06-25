#!/bin/bash
# publish-public.sh — Push only rice/dotfiles to GitHub, no scripts/docs/ssh.
# Called optionally after dotsync.

set -e

REPO_SOURCE="$HOME/Dotfiles"
TEMP_DIR=$(mktemp -d)
GH_REMOTE="git@github.com:sn0wmann1/snowdots.git"

# Directories to keep on GitHub (rice + dotfiles only)
KEEP_DIRS="
  autostart bash bin brave btop caelestia fastfetch fish
  hypr kitty matugen quickshell sddm skwd-wall starship systemd
"

cleanup() { rm -rf "$TEMP_DIR"; }
trap cleanup EXIT

echo "📦 Cloning repo to temp..."
git clone "$REPO_SOURCE" "$TEMP_DIR/snowdots" 2>/dev/null
cd "$TEMP_DIR/snowdots"

# Also explicitly remove hidden dirs that shouldn't be public
rm -rf .opencode/ .ssh/ .config/

echo "🧹 Pruning non-rice files..."
shopt -s dotglob
for item in *; do
  keep=false
  for d in $KEEP_DIRS; do
    [ "$item" = "$d" ] && keep=true && break
  done
  [ "$item" = ".gitattributes" ] && keep=true
  [ "$item" = ".gitignore" ] && keep=true
  [ "$item" = ".nanorc" ] && keep=true
  [ "$item" = "README.md" ] && keep=true
  [ "$item" = ".git" ] && keep=true
  $keep || rm -rf "$item"
done
shopt -u dotglob

# Strip IPs + Tailscale domains + local hostnames from remaining files
find . -name .git -prune -o -type f -exec sed -i \
  -e 's/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/0.0.0.0/g' \
  -e 's/\(snow@\)[0-9.]\+/\10.0.0.0/g' \
  -e 's/\.[a-z]*\.ts\.net/.ts.net/g' \
  {} + 2>/dev/null || true

# Start fresh — orphan branch, no history, one clean commit
git checkout --orphan gh-publish 2>/dev/null
git add -A

echo "📦 Committing..."
# Generate a description of what's in the repo for the public mirror
KEEP_LIST=$(echo "$KEEP_DIRS" | tr '\n' ' ' | xargs)
GIT_AUTHOR_NAME="sn0wmann1" GIT_AUTHOR_EMAIL="sn0wmann1@users.noreply.github.com" \
GIT_COMMITTER_NAME="sn0wmann1" GIT_COMMITTER_EMAIL="sn0wmann1@users.noreply.github.com" \
git commit -m "feat: Hyprland rice — matugen Material You, Caelestia QML shell

Components: $KEEP_LIST
Updated: $(date +%F)"

echo "🚀 Force-pushing to GitHub..."
git push "$GH_REMOTE" gh-publish:main --force 2>/dev/null || echo "⚠️  Push failed"
