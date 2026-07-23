#!/usr/bin/env python3
"""Set MAD68 HE keyboard RGB using hub.f.gg protocol (solid color)"""
import hid, sys

VID, PID, INTERFACE = 0x373B, 0x1058, 1

if len(sys.argv) < 2:
    sys.exit(1)

hex_color = sys.argv[1].lstrip('#')
brightness_pct = int(sys.argv[2]) if len(sys.argv) > 2 else 70

r, g, b = int(hex_color[0:2], 16), int(hex_color[2:4], 16), int(hex_color[4:6], 16)
brightness = max(0, min(255, int(brightness_pct * 255 / 100)))

target = None
for d in hid.enumerate(VID, PID):
    if d.get('interface_number') == INTERFACE:
        target = d['path']
        break
if not target:
    sys.exit(1)

dev = hid.device()
dev.open_path(target)

data = bytearray([7, 65, 2, 0, 0x96, r, g, b, brightness, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0])
dev.write(bytes(data))
dev.close()
