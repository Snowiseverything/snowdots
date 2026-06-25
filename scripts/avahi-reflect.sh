#!/bin/bash
# Enable avahi mDNS reflection for Anytype P2P sync over Tailscale
# Run with sudo

sed -i 's/#enable-reflector=no/enable-reflector=yes/' /etc/avahi/avahi-daemon.conf
systemctl restart avahi-daemon
echo "Avahi reflection enabled. mDNS now bridges LAN ↔ Tailscale."
