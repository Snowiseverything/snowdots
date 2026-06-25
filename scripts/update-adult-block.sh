#!/bin/bash
# Update /etc/hosts with adult site blocklist from StevenBlack
# Run with sudo to install

set -e

URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn-only/hosts"
WORK=$(mktemp -d)
HEADER="$WORK/header"
BLOCKLIST="$WORK/blocklist"
MERGED="$WORK/merged"

cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

# Extract local system entries from current /etc/hosts
grep -E '^(#|127\.|::1|ff02)' /etc/hosts > "$HEADER"
grep '100\.83\.33\.67' /etc/hosts >> "$HEADER"

# Download blocklist
echo "Downloading adult blocklist..."
curl -sL "$URL" -o "$BLOCKLIST"

# Count domains
DOMAINS=$(grep -c '^0\.0\.0\.0' "$BLOCKLIST")
echo "Found $DOMAINS blocked domains"

# Merge: system header + adult entries
cat "$HEADER" > "$MERGED"
echo "" >> "$MERGED"
echo "# === Adult site blocklist ($DOMAINS domains, $(date -I)) ===" >> "$MERGED"
grep '^0\.0\.0\.0' "$BLOCKLIST" >> "$MERGED"

# Install
cp "$MERGED" /etc/hosts
echo "Installed to /etc/hosts ($DOMAINS adult domains blocked)"
