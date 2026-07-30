#!/usr/bin/env python3
"""Fade PC RGB devices (OpenRGB + MAD68) smoothly."""

import sys, time
from pathlib import Path

LAST_COLOR = Path("/tmp/fade-rgb-last")
FADE_STEPS = 10
FADE_DELAY_MS = 20
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


def fade_all(target_r, target_g, target_b, frames, brightness_pct, last_color=None):
    """Fade OpenRGB + keyboard without mode switch — no flash."""
    orgb = None
    kb_dev = None
    try:
        from openrgb import OpenRGBClient
        from openrgb.utils import RGBColor

        for attempt in range(3):
            try:
                orgb = OpenRGBClient(OPENRGB_HOST, OPENRGB_PORT)
                break
            except Exception:
                time.sleep(0.5)

        # Stay in current mode (Static). No _direct() — mode switches cause flash.

        import hid
        for d in hid.enumerate(MAD68_VID, MAD68_PID):
            if d.get("usage_page") == MAD68_RGB_USAGE_PAGE:
                kb_dev = hid.device()
                kb_dev.open_path(d["path"])
                break
    except Exception:
        pass

    if orgb is None and kb_dev is None:
        return

    for ri, gi, bi in frames:
        color = RGBColor(ri, gi, bi)

        if orgb is not None:
            for d in orgb.devices:
                try:
                    # Force Direct mode — Static mode on ASUS ignores per-LED colors
                    if d.active_mode != 0:
                                        d.set_mode(0)
                    d.set_colors([color] * len(d.leds))
                    d.show()
                except Exception:
                    pass

        if kb_dev is not None:
            try:
                _mad68_send_color(kb_dev, ri, gi, bi)
            except Exception:
                pass

        time.sleep(FADE_DELAY_MS / 1000)

    if orgb is not None:
        try:
            orgb.disconnect()
        except Exception:
            pass

    if kb_dev is not None:
        try:
            kb_dev.close()
        except Exception:
            pass


MAD68_VID = 0x373B
MAD68_PID = 0x1058
MAD68_INTERFACE = 1
MAD68_REPORT_LEN = 33
MAD68_RGB_USAGE_PAGE = 0xFF60
MAD68_NUM_SLOTS = 80
MAD68_KEYS_PER_PACKET = 8
MAD68_NUM_CHUNKS = 5
MAD68_SUB_OFFSETS = (0x00, 0x08)
MAD68_FRAME_DELAY = .030
MAD68_PACKET_DELAY = 0


def _mad68_send_color(dev, r, g, b):
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

    factor = max(0, min(100, brightness)) / 100.0
    target_r, target_g, target_b = int(r * factor), int(g * factor), int(b * factor)

    last = read_last()
    if last is None:
        frames = [(target_r, target_g, target_b)]
    else:
        fr, fg, fb = last
        if fr == target_r and fg == target_g and fb == target_b:
            print(f"Already #{r:02x}{g:02x}{b:02x} at {brightness}%")
            return
        frames = interpolate(fr, fg, fb, target_r, target_g, target_b)

    fade_all(target_r, target_g, target_b, frames, brightness, last)

    write_last(target_r, target_g, target_b)
    print(f"Set #{r:02x}{g:02x}{b:02x} at {brightness}%")


if __name__ == "__main__":
    main()
