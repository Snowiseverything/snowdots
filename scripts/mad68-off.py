#!/usr/bin/env python3
"""Turn off MAD68 HE keyboard LEDs using per-slot protocol.

Uses the same packet format as madlions-configurator:
  - 10 data packets (CMD_SET_COLORS = 0x42) setting all 80 slots to (0,0,0)
  - 1 commit packet (CMD_COMMIT = 0x41)

The solid-color shortcut used by mad68-rgb.py (single commit with mode=2)
doesn't properly turn off LEDs — the keyboard needs explicit per-slot black.
"""
import hid, sys

VID, PID, INTERFACE = 0x373B, 0x1058, 1
REPORT_LEN = 33
REPORT_ID = 0x07
CMD_SET_COLORS = 0x42
CMD_COMMIT = 0x41
NUM_SLOTS = 80
KEYS_PER_PACKET = 8
NUM_CHUNKS = 5
SUB_OFFSETS = (0x00, 0x08)


def build_color_packets():
    """Build 10 data packets with all slots set to black (0,0,0)."""
    packets = []
    idx = 0
    for chunk in range(NUM_CHUNKS):
        for sub in SUB_OFFSETS:
            pkt = bytearray(REPORT_LEN)
            pkt[0] = 0x00
            pkt[1] = REPORT_ID
            pkt[2] = CMD_SET_COLORS
            pkt[3] = chunk
            pkt[4] = sub
            pkt[5] = KEYS_PER_PACKET
            # All black — no need to write RGB bytes (already zero)
            packets.append(bytes(pkt))
            idx += KEYS_PER_PACKET
    return packets


def build_commit_packet():
    """Build commit/apply packet."""
    pkt = bytearray(REPORT_LEN)
    pkt[0] = 0x00
    pkt[1] = REPORT_ID
    pkt[2] = CMD_COMMIT
    pkt[3] = 0x01
    pkt[5] = 0x90
    pkt[6] = 0xFF
    pkt[8] = 0xEE
    pkt[9] = 0xD2
    return bytes(pkt)


def main():
    # Find the MAD68 HID interface
    target = None
    for d in hid.enumerate(VID, PID):
        if d.get('interface_number') == INTERFACE:
            target = d['path']
            break
    if not target:
        print("MAD68 keyboard not found", file=sys.stderr)
        sys.exit(1)

    dev = hid.device()
    dev.open_path(target)

    # Send 10 per-slot data packets (all black)
    for pkt in build_color_packets():
        dev.write(pkt)

    # Send commit packet
    dev.write(build_commit_packet())

    dev.close()
    print("ok")


if __name__ == "__main__":
    main()
