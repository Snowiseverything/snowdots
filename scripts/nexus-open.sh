#!/usr/bin/env bash
# Open Caelestia Nexus settings as floating, centered window

quickshell ipc -c caelestia call nexus open

for _ in 1 2 3 4 5; do
    addr=$(hyprctl clients -j 2>/dev/null | python3 -c "
import sys, json
clients = json.load(sys.stdin)
for c in clients:
    if c.get('title', '').startswith('Nexus'):
        print(c['address'])
        break
")
    [ -n "$addr" ] && break
    sleep 0.1
done

[ -z "$addr" ] && exit 0

hyprctl dispatch togglefloating "address:$addr"
sleep 0.15
hyprctl dispatch centerwindow "address:$addr"
