#!/usr/bin/env python3
"""Set MAD68 HE keyboard RGB to a single static color"""
import hid, sys

VID, PID, INTERFACE = 0x373B, 0x1058, 1
MATRIX_SIZE = 384  # 128 keys × 3 bytes (RGB)

if len(sys.argv) < 2:
    print("Usage: mad68-rgb.py RRGGBB", file=sys.stderr)
    sys.exit(1)

hex_color = sys.argv[1].lstrip('#')
if len(hex_color) != 6:
    print("Invalid color: must be 6 hex digits", file=sys.stderr)
    sys.exit(1)

r, g, b = int(hex_color[0:2], 16), int(hex_color[2:4], 16), int(hex_color[4:6], 16)

target = None
for d in hid.enumerate(VID, PID):
    if d.get('interface_number') == INTERFACE:
        target = d['path']
        break

if not target:
    sys.exit(1)

dev = hid.device()
try:
    dev.open_path(target)
except OSError:
    sys.exit(1)

matrix = bytearray([r, g, b] * (MATRIX_SIZE // 3))

def checksum(payload):
    return sum(payload[4:]) & 0xFF

offset = 0
ci = 0
while offset < MATRIX_SIZE:
    sz = min(56, MATRIX_SIZE - offset)
    chunk = matrix[offset:offset + sz]
    pkt = bytearray(64)
    pkt[0:2] = b'\x55\x0B'
    pkt[4] = sz
    pkt[5] = offset & 0xFF
    pkt[6] = (offset >> 8) & 0xFF
    pkt[7] = 0x01 if offset == 0 else 0x00
    for i in range(sz):
        pkt[8 + i] = chunk[i]
    pkt[3] = checksum(pkt)
    try:
        dev.write(b'\x00' + bytes(pkt))
    except:
        break
    offset += sz
    ci += 1

dev.close()
