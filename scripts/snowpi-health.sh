#!/bin/bash
# Snowpi health monitor - switches DNS/NTP between Snowpi and fallback
# Also writes /tmp/health-status for bar icon

SNOWPI_LAN="192.168.1.35"
SNOWPI_TS="100.83.33.67"
ROUTER="192.168.0.1"
FALLBACK_DNS="1.1.1.1"
NTP_FALLBACK="0.arch.pool.ntp.org time.google.com"
STATE_FILE="/run/snowpi-health.state"
HEALTH_FILE="/tmp/health-status"
NTP_DROPIN="/etc/systemd/timesyncd.conf.d/snowpi.conf"
IFACE="enp6s0"

ping -c 1 -W 2 $SNOWPI_LAN >/dev/null 2>&1 || ping -c 1 -W 2 $SNOWPI_TS >/dev/null 2>&1
SNOWPI_UP=$?

ping -c 1 -W 3 1.1.1.1 >/dev/null 2>&1
INTERNET_UP=$?

dig +short google.com @$ROUTER >/dev/null 2>&1
DNS_OK=$?

printf "snowpi=%s\ninternet=%s\ndns=%s\n" \
  "$( [ $SNOWPI_UP -eq 0 ] && echo up || echo down )" \
  "$( [ $INTERNET_UP -eq 0 ] && echo ok || echo down )" \
  "$( [ $DNS_OK -eq 0 ] && echo ok || echo fail )" > "$HEALTH_FILE"

[ $SNOWPI_UP -eq 0 ] && NEW_STATE="up" || NEW_STATE="down"

OLD_STATE=""
[ -f "$STATE_FILE" ] && OLD_STATE=$(cat "$STATE_FILE")

[ "$NEW_STATE" = "$OLD_STATE" ] && exit 0

logger "snowpi-health: $OLD_STATE -> $NEW_STATE"

if [ "$NEW_STATE" = "up" ]; then
    resolvectl dns $IFACE $SNOWPI_LAN $SNOWPI_TS
    resolvectl domain $IFACE "~." "~snowfinch-catfish.ts.net"
    printf "[Time]\nNTP=%s\nFallbackNTP=%s\n" "$SNOWPI_TS" "$NTP_FALLBACK" > "$NTP_DROPIN"
else
    resolvectl dns $IFACE $ROUTER $FALLBACK_DNS
    resolvectl domain $IFACE "~snowfinch-catfish.ts.net"
    printf "[Time]\nNTP=%s\n" "$NTP_FALLBACK" > "$NTP_DROPIN"
fi

systemctl restart systemd-timesyncd
echo "$NEW_STATE" > "$STATE_FILE"
