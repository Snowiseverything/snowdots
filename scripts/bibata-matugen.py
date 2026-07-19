#!/usr/bin/env python3
"""Recolor Bibata cursor theme using matugen accent color."""

import concurrent.futures
import glob
import json
import os
import shutil
import subprocess
import sys

COLORS_FILE = os.path.expanduser("~/.cache/skwd-wall/colors.json")
BIBATA_SRC = os.path.expanduser("~/Dotfiles/scripts/bibata-src")
THEME_NAME = "Bibata-Matugen"
OUT_DIR = os.path.expanduser("~/.local/share/icons")
BITMAPS_DIR = os.path.join(BIBATA_SRC, "bitmaps", THEME_NAME)

SVG_MODERN = os.path.join(BIBATA_SRC, "svg", "modern")
SVG_GROUPS = os.path.join(BIBATA_SRC, "svg", "groups")
PLACEHOLDER_BASE = "#00FF00"
PLACEHOLDER_OUTLINE = "#0000FF"
PLACEHOLDER_WATCH = "#FF0000"


def hex_to_rgb(hex_color):
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i : i + 2], 16) for i in (0, 2, 4))


def relative_luminance(r, g, b):
    def chan(c):
        c = c / 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    return 0.2126 * chan(r) + 0.7152 * chan(g) + 0.0722 * chan(b)


def get_matugen_colors():
    with open(COLORS_FILE) as f:
        data = json.load(f)

    accent = data.get("accent", "#b7d084")
    if accent.startswith("0x"):
        accent = "#" + accent[2:]

    r, g, b = hex_to_rgb(accent)
    lum = relative_luminance(r, g, b)

    outline = "#FFFFFF" if lum < 0.5 else "#000000"
    watch_bg = "#000000" if lum > 0.3 else "#FFFFFF"

    return {"base": accent, "outline": outline, "watch_bg": watch_bg}


def recolor_svg(src_path, dest_path, colors):
    with open(src_path) as f:
        content = f.read()
    content = content.replace(PLACEHOLDER_BASE, colors["base"])
    content = content.replace(PLACEHOLDER_OUTLINE, colors["outline"])
    content = content.replace(PLACEHOLDER_WATCH, colors["watch_bg"])
    with open(dest_path, "w") as f:
        f.write(content)


def render_png(svg_path, png_path):
    subprocess.run(
        ["rsvg-convert", "-w", "256", "-h", "256", svg_path, "-o", png_path],
        capture_output=True,
    )


def collect_svg_tasks(work_dir):
    tasks = []

    static_from = SVG_MODERN
    for entry in os.scandir(static_from):
        if entry.is_file() and entry.name.endswith(".svg"):
            src = os.path.realpath(entry.path)
            dst = os.path.join(work_dir, entry.name)
            out_png = os.path.join(
                BITMAPS_DIR, entry.name.replace(".svg", ".png")
            )
            tasks.append((src, dst, out_png))

    anim_dirs = [
        ("left_ptr_watch", os.path.join(SVG_GROUPS, "modern", "left_ptr_watch")),
        ("wait", os.path.join(SVG_GROUPS, "shared", "wait")),
    ]
    for name, anim_dir in anim_dirs:
        if not os.path.isdir(anim_dir):
            continue
        for frame in sorted(glob.glob(os.path.join(anim_dir, "*.svg"))):
            base = os.path.basename(frame)
            dst = os.path.join(work_dir, base)
            out_png = os.path.join(BITMAPS_DIR, base.replace(".svg", ".png"))
            tasks.append((frame, dst, out_png))

    return tasks


def render_svgs(colors):
    work_dir = os.path.join(BIBATA_SRC, ".recolor-work")
    if os.path.isdir(work_dir):
        shutil.rmtree(work_dir)
    if os.path.isdir(BITMAPS_DIR):
        shutil.rmtree(BITMAPS_DIR)
    os.makedirs(work_dir)
    os.makedirs(BITMAPS_DIR)

    tasks = collect_svg_tasks(work_dir)

    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        recolor_futures = [
            pool.submit(recolor_svg, src, dst, colors) for src, dst, _ in tasks
        ]
        concurrent.futures.wait(recolor_futures)

        render_futures = [
            pool.submit(render_png, dst, png) for _, dst, png in tasks
        ]
        concurrent.futures.wait(render_futures)

    shutil.rmtree(work_dir)


def build_xcursor():
    cfg_dir = os.path.join(BIBATA_SRC, "configs", "normal")
    theme_out = os.path.join(BIBATA_SRC, "themes", THEME_NAME)
    if os.path.isdir(theme_out):
        shutil.rmtree(theme_out)
    result = subprocess.run(
        [
            "ctgen",
            os.path.join(cfg_dir, "x.build.toml"),
            "-p", "x11",
            "-d", BITMAPS_DIR,
            "-n", THEME_NAME,
            "-c", "Matugen-colored Bibata cursors",
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"ctgen error: {result.stderr}", file=sys.stderr)
        sys.exit(1)

    theme_dir = os.path.join(BIBATA_SRC, "themes", THEME_NAME)
    if not os.path.isdir(theme_dir):
        print(f"ctgen did not produce theme at {theme_dir}", file=sys.stderr)
        sys.exit(1)
    return theme_dir


def install_theme(theme_dir):
    dest = os.path.join(OUT_DIR, THEME_NAME)
    if os.path.isdir(dest):
        shutil.rmtree(dest)
    shutil.copytree(theme_dir, dest, symlinks=True)
    return dest


def apply_cursor():
    subprocess.run(
        ["gsettings", "set", "org.gnome.desktop.interface", "cursor-theme", THEME_NAME],
        capture_output=True,
    )
    subprocess.run(
        ["hyprctl", "setcursor", THEME_NAME, "24"],
        capture_output=True,
    )
    subprocess.run(["hyprctl", "reload"], capture_output=True)


def main():
    if not os.path.isdir(BIBATA_SRC):
        print(f"Bibata source not found at {BIBATA_SRC}", file=sys.stderr)
        sys.exit(1)

    if not os.path.isfile(COLORS_FILE):
        print(f"Matugen colors file not found at {COLORS_FILE}", file=sys.stderr)
        sys.exit(1)

    colors = get_matugen_colors()
    prev_file = os.path.join(BIBATA_SRC, ".prev-accent")
    prev_accent = ""
    if os.path.isfile(prev_file):
        with open(prev_file) as f:
            prev_accent = f.read().strip()

    if prev_accent == colors["base"]:
        return

    render_svgs(colors)
    theme_dir = build_xcursor()
    install_theme(theme_dir)
    apply_cursor()

    with open(prev_file, "w") as f:
        f.write(colors["base"])

    print(
        f"Bibata-Matugen cursor applied: "
        f"base={colors['base']}, outline={colors['outline']}"
    )


if __name__ == "__main__":
    main()
