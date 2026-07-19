#!/usr/bin/env python3
"""Fade PC RGB devices (OpenRGB + MAD68) smoothly.

Usage:
  fade-rgb.py <hex_color>               # set color (e.g. ff00ff)
  fade-rgb.py <hex_color> <brightness>  # set color + brightness (0-100)

Govee LED runs separately via govee-led.py (BLE is slower).
"""
import sys, time, threading
from pathlib import Path

LAST_COLOR = Path("/tmp/fade-rgb-last")
FADE_STEPS = 20
FADE_DELAY_MS = 30
OPENRGB_HOST = "localhost"
OPENRGB_PORT = 6742


def read_last():
    if LAST_COLOR.exists():
        parts = LAST_COLOR.read_text().strip().split()
        if len(parts) >= 3:
            return int(parts[0]), int(parts[1]), int(parts[2])
    return None


def write_last(r, g, b):
    LAST_COLOR.write_text(f"{r} {g} {b}\n")


def ease(t):
    return t * t * (3 - 2 * t)


def interpolate(fr, fg, fb, r, g, b):
    frames = []
    for i in range(1, FADE_STEPS + 1):
        t = ease(i / FADE_STEPS)
        ri = int(round(fr + (r - fr) * t))
        gi = int(round(fg + (g - fg) * t))
        bi = int(round(fb + (b - fb) * t))
        frames.append((ri, gi, bi))
    return frames


def fade_openrgb(frames):
    from openrgb import OpenRGBClient
    from openrgb.utils import RGBColor

    client = None
    for attempt in range(5):
        try:
            client = OpenRGBClient(OPENRGB_HOST, OPENRGB_PORT)
            break
        except Exception:
            time.sleep(1)
    if client is None:
        print("OpenRGB: server not available after 5 retries", file=sys.stderr)
        return

    try:
        for d in client.devices:
            if d.active_mode != 0:
                d.set_mode(0)
    except Exception:
        pass

    for ri, gi, bi in frames:
        try:
            color = RGBColor(ri, gi, bi)
            for d in client.devices:
                d.set_colors([color] * len(d.leds))
                d.show()
        except Exception:
            pass
        time.sleep(FADE_DELAY_MS / 1000)


MAD68_VID = 0x373B
MAD68_PID = 0x1058
MAD68_INTERFACE = 1
MAD68_REPORT_LEN = 33
MAD68_RGB_USAGE_PAGE = 0xFF60
MAD68_NUM_SLOTS = 80
MAD68_KEYS_PER_PACKET = 8
MAD68_NUM_CHUNKS = 5
MAD68_SUB_OFFSETS = (0x00, 0x08)
MAD68_FRAME_DELAY = 0.030  # match OpenRGB's 30ms per-frame timing
MAD68_PACKET_DELAY = 0      # keyboard handles back-to-back writes fine


def _mad68_send_color(dev, r, g, b):
    """Send a solid color to all slots using the MAD68 protocol (set+commit)."""
    slots = [(r, g, b)] * MAD68_NUM_SLOTS
    idx = 0
    for chunk in range(MAD68_NUM_CHUNKS):
        for sub in MAD68_SUB_OFFSETS:
            pkt = bytearray(MAD68_REPORT_LEN)
            pkt[0] = 0x00
            pkt[1] = 0x07
            pkt[2] = 0x42
            pkt[3] = chunk
            pkt[4] = sub
            pkt[5] = MAD68_KEYS_PER_PACKET
            for k in range(MAD68_KEYS_PER_PACKET):
                cr, cg, cb = slots[idx]
                pkt[6 + k * 3] = cr
                pkt[7 + k * 3] = cg
                pkt[8 + k * 3] = cb
                idx += 1
            dev.write(bytes(pkt))
            time.sleep(MAD68_PACKET_DELAY)

    commit = bytearray(MAD68_REPORT_LEN)
    commit[0] = 0x00
    commit[1] = 0x07
    commit[2] = 0x41
    commit[3] = 0x01
    commit[5] = 0x90
    commit[6] = 0xFF
    commit[8] = 0xEE
    commit[9] = 0xD2
    dev.write(bytes(commit))
    time.sleep(MAD68_PACKET_DELAY)


def fade_mad68(frames, brightness_pct):
    try:
        import hid

        target = None
        for d in hid.enumerate(MAD68_VID, MAD68_PID):
            if d.get("usage_page") == MAD68_RGB_USAGE_PAGE:
                target = d["path"]
                break
        if not target:
            return
        dev = hid.device()
        dev.open_path(target)
        for ri, gi, bi in frames:
            _mad68_send_color(dev, ri, gi, bi)
            time.sleep(MAD68_FRAME_DELAY)
        dev.close()
    except Exception:
        pass


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__.strip())
        return

    r = g = b = 0
    brightness = 100
    hex_color = args[0].lstrip("#")
    if len(hex_color) >= 6:
        r, g, b = int(hex_color[0:2], 16), int(hex_color[2:4], 16), int(hex_color[4:6], 16)
    if len(args) > 1:
        brightness = int(args[1])

    last = read_last()
    fr, fg, fb = last if last else (0, 0, 0)  # boot: fade from black

    frames = interpolate(fr, fg, fb, r, g, b)

    threads = [
        threading.Thread(target=fade_openrgb, args=(frames,)),
        threading.Thread(target=fade_mad68, args=(frames, brightness)),
    ]

    for t in threads:
        t.start()
    for t in threads:
        t.join()

    write_last(r, g, b)
    print(f"Faded #{r:02x}{g:02x}{b:02x} at {brightness}%")


if __name__ == "__main__":
    main()
