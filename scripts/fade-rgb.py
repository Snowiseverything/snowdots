#!/usr/bin/env python3
"""Fade PC RGB devices (OpenRGB + MAD68) smoothly."""

import sys, time
from pathlib import Path

# ── Config ────────────────────────────────────────────────────────────────
sys.path.insert(0, str(Path.home() / ".local/bin"))
try:
    from rgb_config import load_config, config_value  # pyright: ignore[reportMissingImports]
    _CFG = load_config()
except Exception:
    _CFG = None
    config_value = None  # type: ignore[assignment]


def _cfg(key, default):
    """Get config value or fall back to default."""
    if _CFG is None or config_value is None:
        return default
    keys = key.split(".")
    return config_value(_CFG, *keys, default=default)


LAST_COLOR = Path("/tmp/fade-rgb-last")
RAW_LAST = Path("/tmp/fade-rgb-raw-last")
FADE_STEPS = _cfg("fade.steps", 10)
FADE_DELAY_MS = _cfg("fade.delay_ms", 20)
OPENRGB_HOST = _cfg("openrgb.host", "localhost")
OPENRGB_PORT = _cfg("openrgb.port", 6742)

MAD68_VID = 0x373B
MAD68_PID = 0x1058
MAD68_INTERFACE = 1
MAD68_REPORT_LEN = 33
MAD68_RGB_USAGE_PAGE = 0xFF60
MAD68_NUM_SLOTS = 80
MAD68_KEYS_PER_PACKET = 8
MAD68_NUM_CHUNKS = 5
MAD68_SUB_OFFSETS = (0x00, 0x08)
MAD68_FRAME_DELAY = _cfg("keyboard.frame_delay_ms", 30) / 1000
MAD68_PACKET_DELAY = _cfg("keyboard.packet_delay_ms", 0) / 1000

# openrgb is optional — scripts can run headless (keyboard-only). Importing
# the class at module level lets pyright see it as bound.
try:
    from openrgb.utils import RGBColor  # pyright: ignore[reportMissingImports]
except Exception:  # noqa: BLE001
    RGBColor = None  # type: ignore[assignment]


def _safe_int(v, default=0):
    """int() with fallback — config/file input can be malformed."""
    try:
        return int(v)
    except (TypeError, ValueError, OverflowError):
        return default


def read_last():
    if LAST_COLOR.exists():
        parts = LAST_COLOR.read_text().strip().split()
        if len(parts) >= 3:
            return _safe_int(parts[0]), _safe_int(parts[1]), _safe_int(parts[2])
    return None


def write_last(r, g, b):
    LAST_COLOR.write_text(f"{r} {g} {b}\n")


def read_raw_last():
    """Read raw (undimmed) last color."""
    if RAW_LAST.exists():
        parts = RAW_LAST.read_text().strip().split()
        if len(parts) >= 3:
            return _safe_int(parts[0]), _safe_int(parts[1]), _safe_int(parts[2])
    return None


def write_raw_last(r, g, b):
    RAW_LAST.write_text(f"{r} {g} {b}\n")


def ease(t):
    return t * t * (3 - 2 * t)


def interpolate(fr, fg, fb, r, g, b):
    frames = []
    for i in range(1, FADE_STEPS + 1):
        t = ease(i / FADE_STEPS)
        ri = round(fr + (r - fr) * t)
        gi = round(fg + (g - fg) * t)
        bi = round(fb + (b - fb) * t)
        frames.append((ri, gi, bi))
    return frames


def _mad68_set_brightness(dev, r, g, b, pct):
    """Set hardware brightness via solid-color packet (brightness byte).

    Same packet format as mad68-rgb.py — the per-slot color protocol has no
    brightness field, so the hardware dim level is set here and the per-slot
    colors render at it.
    """
    bri = max(0, min(255, _safe_int(pct * 255 / 100, 255)))
    pkt = bytearray([7, 65, 2, 0, 0x96, r, g, b, bri, 0, 0, 0, 0, 0, 0, 0, 0,
                     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
    dev.write(bytes(pkt))
    time.sleep(MAD68_PACKET_DELAY)


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
            # pi-lens-ignore: python-sleep-in-test
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
    # pi-lens-ignore: python-sleep-in-test
    time.sleep(MAD68_PACKET_DELAY)


def fade_all(frames, kb_frames, brightness_pct, pc_brightness=100):
    """Fade OpenRGB + keyboard.

    frames — dimmed RGB for OpenRGB (pre-scaled by brightness factor)
    kb_frames — raw RGB for keyboard (hardware brightness handles dimming)
    brightness_pct — keyboard hardware-dim level (0-100)
    pc_brightness — OpenRGB brightness (0-100). When 0 the PC devices are off
        and their color writes are skipped so we don't flash a transition to
        black — they just stay off while the keyboard still syncs.
    """
    orgb = None
    kb_dev = None
    try:
        import socket
        from openrgb import OpenRGBClient
        from openrgb.utils import RGBColor

        # Wait for the OpenRGB SDK listener — at boot the server takes
        # several seconds to init hardware before accepting connections.
        for _attempt in range(20):
            try:
                with socket.create_connection((OPENRGB_HOST, OPENRGB_PORT), timeout=1):
                    break
            except OSError:
                time.sleep(0.5)

        for _attempt in range(5):
            try:
                orgb = OpenRGBClient(OPENRGB_HOST, OPENRGB_PORT)
                break
            except Exception:
                time.sleep(1.0)

        import hid  # pyright: ignore[reportMissingImports]
        for d in hid.enumerate(MAD68_VID, MAD68_PID):
            if d.get("usage_page") == MAD68_RGB_USAGE_PAGE:
                kb_dev = hid.device()
                kb_dev.open_path(d["path"])
                break
    except Exception:
        pass

    if orgb is None and kb_dev is None:
        return

    for i, (ri, gi, bi) in enumerate(frames):
        if orgb is not None and pc_brightness > 0:
            color = RGBColor(ri, gi, bi)  # pyright: ignore[reportOptionalCall]
            for d in orgb.devices:
                try:
                    if d.active_mode != 0:
                        d.set_mode(0)
                    d.set_colors([color] * len(d.leds))
                    d.show()
                except Exception:
                    pass

        if kb_dev is not None and i < len(kb_frames):
            try:
                if i == 0 and kb_frames:
                    kr0, kg0, kb0 = kb_frames[-1]
                    _mad68_set_brightness(kb_dev, kr0, kg0, kb0, brightness_pct)
                kr, kg, kb = kb_frames[i]
                _mad68_send_color(kb_dev, kr, kg, kb)
            except Exception:
                pass

        # pi-lens-ignore: python-sleep-in-test
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


def main():
    args = sys.argv[1:]
    if not args:
        print((__doc__ or "").strip())
        return

    r = g = b = 0
    brightness = 100
    kb_brightness = None  # separate keyboard dim — defaults to brightness
    hex_color = args[0].lstrip("#")
    if len(hex_color) >= 6:
        try:
            r, g, b = int(hex_color[0:2], 16), int(hex_color[2:4], 16), int(hex_color[4:6], 16)
        except ValueError:
            r = g = b = 0
    if len(args) > 1:
        brightness = _safe_int(args[1], 100)
    if len(args) > 2:
        kb_brightness = _safe_int(args[2], brightness)

    kb_dim = brightness if kb_brightness is None else kb_brightness
    factor = max(0, min(100, brightness)) / 100.0
    target_r, target_g, target_b = round(r * factor), round(g * factor), round(b * factor)
    raw_target = (r, g, b)

    last = read_last()
    raw_last = read_raw_last() if last else None

    if last is None:
        orgb_frames = [(target_r, target_g, target_b)]
        kb_frames = [(r, g, b)]
    else:
        fr, fg, fb = last
        if fr == target_r and fg == target_g and fb == target_b:
            # Color matches but devices might be in Off mode — force wake
            fade_all([(target_r, target_g, target_b)], [(r, g, b)], kb_dim, brightness)
            write_last(target_r, target_g, target_b)
            write_raw_last(r, g, b)
            print(f"Set #{r:02x}{g:02x}{b:02x} at {brightness}%")
            return
        orgb_frames = interpolate(fr, fg, fb, target_r, target_g, target_b)
        if raw_last is not None:
            krf, kgf, kbf = raw_last
            kb_frames = interpolate(krf, kgf, kbf, r, g, b)
        else:
            kb_frames = interpolate(fr, fg, fb, r, g, b)

    fade_all(orgb_frames, kb_frames, kb_dim, brightness)

    write_last(target_r, target_g, target_b)
    write_raw_last(r, g, b)
    print(f"Set #{r:02x}{g:02x}{b:02x} at {brightness}%")


if __name__ == "__main__":
    main()
