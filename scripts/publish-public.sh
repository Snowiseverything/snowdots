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
    -e 's/git fetch remote/git fetch remote/g' \
    -e 's/git push remote/git push remote/g' \
    -e 's/git pull remote/git pull remote/g' \
