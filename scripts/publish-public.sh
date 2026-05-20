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

# Remove SSH keys, keep placeholder
cat > ssh/authorized_keys << 'EOF'
# Add your public keys here (one per line)
# paste-your-public-key-here
EOF

# Replace specific IPs with placeholders
find . -type f \( -name '*.sh' -o -name '*.fish' -o -name '*.conf' -o -name '*.md' -o -name '*.toml' \) \
  -exec sed -i \
    -e 's/192\.168\.0\.111/192.168.1.100/g' \
    -e 's/192\.168\.1\.35/192.168.1.200/g' \
    {} +

# Replace specific hostname references in scripts/configs
find . -type f \( -name '*.sh' -o -name '*.fish' \) \
  -exec sed -i \
    -e 's/git fetch snowpi/git fetch remote/g' \
    -e 's/git push snowpi/git push remote/g' \
    -e 's/git pull snowpi/git pull remote/g' \
    -e '/# Add snowpi/,/echo.*snowpi/d' \
    -e '/# Add freezer/,/echo.*freezer/d' \
    {} +

# Remove peer SSH setup from scripts (personal hostnames)
find . -type f -name 'setup-*.sh' -exec sed -i \
  -e '/ssh-keyscan.*192\.168/d' \
  -e '/grep -q "remote"/,/echo.*known_hosts/d' \
  {} +

# Replace personal email references in git configs if any
find . -type f -name '*.gitconfig' -o -name '.gitconfig' 2>/dev/null | while read f; do
  sed -i 's/your@email.com/you@example.com/g' "$f"
done

# Update README to be public-friendly (already done, but ensure no setup refs)
if grep -q 'GitLab\|snowpi\|freezer' README.md 2>/dev/null; then
  echo "ℹ️  README.md may contain personal refs - review before push"
fi

# Remove any .env, token, or credential files
find . -name '.env' -o -name '*.token' -o -name '*cred*' -o -name '*secret*' | while read f; do
  rm -f "$f"
  echo "  removed $f"
done

# Commit sanitized version
git add -A
if git diff --cached --quiet; then
  echo "✅ No changes to publish (already up to date)"
else
  git commit -m "public: sanitized release $(date +%Y-%m-%d)"
fi

# Confirm before pushing
echo ""
echo "🚀 Ready to push to GitHub: $GH_REMOTE"
echo ""
echo "Files changed in this publish:"
git diff --name-only HEAD~1 2>/dev/null || echo "  (first publish)"
echo ""

read -rp "Push to GitHub? [y/N] " confirm
case "$confirm" in
  [yY]|[yY][eE][sS])
    echo "📡 Pushing to GitHub..."
    git push "$GH_REMOTE" main --force
    echo "✅ Published to GitHub"
    ;;
  *)
    echo "⏭️  Skipped push to GitHub"
    exit 0
    ;;
esac
