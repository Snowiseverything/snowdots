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
    try:
        from openrgb import OpenRGBClient
        from openrgb.utils import RGBColor

        client = OpenRGBClient(OPENRGB_HOST, OPENRGB_PORT)

        for d in client.devices:
            if d.active_mode != 0:
                d.set_mode(0)

        for ri, gi, bi in frames:
            color = RGBColor(ri, gi, bi)
            for d in client.devices:
                d.set_colors([color] * len(d.leds))
                d.show()
            time.sleep(FADE_DELAY_MS / 1000)
    except Exception:
        pass


def fade_mad68(frames, brightness_pct):
    try:
        import hid

        VID, PID, INTERFACE = 0x373B, 0x1058, 1
        brightness = max(0, min(255, int(brightness_pct * 255 / 100)))
        target = None
        for d in hid.enumerate(VID, PID):
            if d.get("interface_number") == INTERFACE:
                target = d["path"]
                break
        if not target:
            return
        dev = hid.device()
        dev.open_path(target)
        for ri, gi, bi in frames:
            data = bytearray([7, 65, 2, 0, 0x96, ri, gi, bi, brightness, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
            dev.write(bytes(data))
            time.sleep(FADE_DELAY_MS / 1000)
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
    fr, fg, fb = last if last else (0, 0, 0)

    if fr == r and fg == g and fb == b:
        write_last(r, g, b)
        return

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
