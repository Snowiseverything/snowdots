#!/bin/bash
# Fast toggle adult site block on/off (uses cached blocklist, no download)
# Binds: Super+Shift+A

set -e

# Resolve real user home (sudo changes $HOME to /root)
if [ "$(id -u)" = "0" ] && [ -n "$SUDO_USER" ]; then
  REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
  NOTIFY_USER="$SUDO_USER"
else
  REAL_HOME="$HOME"
  NOTIFY_USER="$USER"
fi

CACHE_DIR="$REAL_HOME/.cache/adult-blocklist"
CLEAN="$CACHE_DIR/clean-hosts"
BLOCKLIST="$CACHE_DIR/blocklist"
MARKER="# === Adult site blocklist"

notify() {
  local uid=$(id -u "$NOTIFY_USER")
  sudo -u "$NOTIFY_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" notify-send "$@"
}

[ -f "$BLOCKLIST" ] && [ -s "$BLOCKLIST" ] || {
  notify -u critical "Adult Block" "No cached blocklist — run cache-adult-blocklist.sh first"
  exit 1
}

write_hosts() {
  if [ "$(id -u)" = "0" ]; then
    cat > /etc/hosts
  else
    cat | sudo tee /etc/hosts > /dev/null
  fi
}

if grep -q "$MARKER" /etc/hosts 2>/dev/null; then
  # ── Disable block ──
  # If no clean backup, extract system entries from current hosts (strip blocklist)
  if [ ! -f "$CLEAN" ]; then
    grep -v '^0\.0\.0\.0' /etc/hosts | grep -v "$MARKER" > "$CLEAN"
  fi
  write_hosts < "$CLEAN"
  notify -i security-high "Adult Block" "OFF" -t 3000
else
  # ── Enable block ──
  cp /etc/hosts "$CLEAN"
  DOMAINS=$(grep -c '^0\.0\.0\.0' "$BLOCKLIST")
  {
    cat "$CLEAN"
    echo ""
    echo "$MARKER ($DOMAINS domains, cached $(date -I))"
    grep '^0\.0\.0\.0' "$BLOCKLIST"
  } | write_hosts
  notify -i security-low "Adult Block" "ON — $DOMAINS domains blocked" -t 3000
fi

resolvectl flush-caches 2>/dev/null || true
