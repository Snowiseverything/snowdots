#!/bin/bash
# Cache adult blocklist from StevenBlack (run via systemd timer, no sudo needed)
set -e

CACHE_DIR="$HOME/.cache/adult-blocklist"
URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn-only/hosts"

mkdir -p "$CACHE_DIR"
curl -sL "$URL" -o "$CACHE_DIR/blocklist"

DOMAINS=$(grep -c '^0\.0\.0\.0' "$CACHE_DIR/blocklist" 2>/dev/null || echo 0)
echo "Cached $DOMAINS adult domains"
