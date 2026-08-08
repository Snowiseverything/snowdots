#!/usr/bin/env python3
"""
SnowVideoDL — full-featured TUI video downloader for 1750+ sites.

Fetches metadata (thumbnail, title, site, uploader, date, duration,
views/likes/comments/shares, description) then lets you pick format
and download via yt-dlp.

Requires:  python3, yt-dlp
Optional:  chafa (thumbnail preview in terminal)

Usage:
  video-dl [URL]
  video-dl --audio URL          audio-only (mp3)
  video-dl --list-formats URL   show all formats, then download one
  video-dl --no-thumb URL       skip thumbnail preview
  video-dl --history            browse download history, open entries
  video-dl --help

When run interactively with no args, prompts for a URL.
"""
from __future__ import annotations

import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import urllib.request
from datetime import datetime
from pathlib import Path

VERSION = "2.0.0"
DL_DIR = Path(os.environ.get("VIDEO_DL_DIR", Path.home() / "Downloads" / "Videos"))
BROWSER_COOKIES = "brave"  # set to "" to disable
ARCHIVE = Path(os.environ.get("VIDEO_DL_ARCHIVE", Path.home() / ".cache" / "video-dl-archive.txt"))
HISTORY = Path(os.environ.get("VIDEO_DL_HISTORY", Path.home() / ".cache" / "video-dl-history.json"))

C = {
    "bold": "\033[1m", "dim": "\033[2m", "red": "\033[31m", "green": "\033[32m",
    "yellow": "\033[33m", "blue": "\033[34m", "magenta": "\033[35m",
    "cyan": "\033[36m", "reset": "\033[0m",
}


def fmt_count(n: int | None) -> str:
    """1234567 -> 1.2M"""
    if n is None:
        return "—"
    try:
        val: float = float(n)
    except (TypeError, ValueError):
        return "—"
    for unit in ("", "K", "M", "B", "T"):
        if val < 1000 or unit == "T":
            return f"{val:.0f}{unit}" if unit == "" else f"{val:.1f}{unit}"
        val /= 1000
    try:
        return str(int(val))
    except (TypeError, ValueError):
        return "—"


def fmt_duration(sec: float | None) -> str:
    if not sec:
        return "—"
    try:
        sec = int(sec)
    except (TypeError, ValueError):
        return "—"
    h, m, s = sec // 3600, (sec % 3600) // 60, sec % 60
    return f"{h}:{m:02d}:{s:02d}" if h else f"{m}:{s:02d}"


def fmt_date(d: str | None) -> str:
    if not d or len(d) < 8:
        return "—"
    return f"{d[0:4]}-{d[4:6]}-{d[6:8]}"


def run_yt(args: list[str], **kw) -> subprocess.CompletedProcess:
    """Run yt-dlp with cookies enabled."""
    if BROWSER_COOKIES:
        args = ["--cookies-from-browser", BROWSER_COOKIES] + args
    return subprocess.run(["yt-dlp", *args], capture_output=True, text=True, **kw)


def clipboard_url() -> str:
    """Detect a video URL in the clipboard (wl-paste, then xclip)."""
    for cmd in (["wl-paste"], ["xclip", "-o", "-selection", "clipboard"]):
        if shutil.which(cmd[0]):
            try:
                r = subprocess.run(cmd, capture_output=True, text=True, timeout=3)
                text = r.stdout.strip()
                if text.startswith(("http://", "https://")):
                    return text
            except (subprocess.SubprocessError, OSError):
                continue
    return ""


def load_history() -> list[dict]:
    """Load download history (newest first)."""
    try:
        data = json.loads(HISTORY.read_text())
        if isinstance(data, list):
            return data
    except (OSError, json.JSONDecodeError):
        pass
    return []


def save_history(entries: list[dict]) -> None:
    try:
        HISTORY.parent.mkdir(parents=True, exist_ok=True)
        HISTORY.write_text(json.dumps(entries, indent=1))
    except OSError:
        pass


def add_history(entry: dict) -> None:
    entries = load_history()
    entries.insert(0, entry)
    save_history(entries[:500])  # cap at 500 entries


def open_media(path: str) -> bool:
    """Open a media file with the system handler (xdg-open). Returns True on success."""
    if not Path(path).exists():
        return False
    opener = os.environ.get("VIDEO_DL_OPENER", "xdg-open")
    try:
        subprocess.Popen([opener, path], stdout=subprocess.DEVNULL,
                         stderr=subprocess.DEVNULL)
        return True
    except OSError:
        return False


def notify_done(title: str, body: str, dest: str | None = None) -> None:
    """Fire a desktop notification with Open / Open folder action buttons.
    Detached so it never blocks the TUI; button clicks handled by the shell.
    """
    if not shutil.which("notify-send"):
        return
    head = title[:120] or "SnowVideoDL"
    nargs = ["notify-send"]
    if dest and Path(dest).exists():
        nargs += ["-A", "open=Open", "-A", "folder=Open folder"]
    nargs += ["⬇ " + head, body]
    if dest and Path(dest).exists():
        # --wait blocks until a button is clicked; run detached and map clicks
        shell = (
            "sel=$(notify-send --wait "
            + " ".join(shlex.quote(a) for a in nargs[1:]) + "); "
            "case \"$sel\" in "
            "open) xdg-open " + shlex.quote(dest) + " ;; "
            "folder) xdg-open " + shlex.quote(str(Path(dest).parent)) + " ;; "
            "esac"
        )
    else:
        shell = "notify-send " + " ".join(shlex.quote(a) for a in nargs[1:]) + " &"
    try:
        subprocess.Popen(["setsid", "sh", "-c", shell],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except OSError:
        pass


def show_history() -> int:
    """Browse download history in fuzzel, open selected file."""
    entries = load_history()
    if not entries:
        print(f"{C['yellow']}No download history yet.{C['reset']}")
        return 0
    choices = []
    for e in entries:
        site = e.get("site", "?")
        title = e.get("title", e.get("url", "?"))
        when = e.get("date", "")
        path = e.get("path", "")
        label = f"{title[:60]}  [{site}] {when}"
        if Path(path).exists():
            label += "  ✓"
        else:
            label += "  ✗ missing"
        choices.append(f"{label}\x1f{path}")
    choices.append("✗ Close")

    if shutil.which("fuzzel"):
        r = subprocess.run(
            ["fuzzel", "--dmenu", "--minimal-lines", "-p", "History: "],
            input="\n".join(choices) + "\n", capture_output=True, text=True)
        sel = r.stdout.strip()
    else:
        print()
        for i, c in enumerate(choices, 1):
            print(f"{C['green']}{i:2}){C['reset']} {c.split('\x1f')[0]}")
        try:
            n = int(input(f"{C['cyan']}➤ Pick [1-{len(choices)}]: {C['reset']}").strip())
        except (ValueError, EOFError):
            return 0
        sel = choices[n - 1] if 1 <= n <= len(choices) else ""

    if not sel or "Close" in sel:
        return 0
    path = sel.split("\x1f")[-1]
    if not path or not Path(path).exists():
        print(f"{C['red']}✗ File missing: {path}{C['reset']}")
        return 1
    print(f"{C['cyan']}▶ Opening: {path}{C['reset']}")
    open_media(path)
    return 0


def fetch_metadata(url: str) -> dict:
    r = run_yt(["--dump-single-json", "--no-warnings", url], timeout=90)
    if r.returncode != 0:
        raise RuntimeError(r.stderr.strip()[-500:] or "yt-dlp failed")
    try:
        return json.loads(r.stdout)
    except json.JSONDecodeError as e:
        raise RuntimeError(f"bad JSON from yt-dlp: {e}") from e


def fetch_thumbnail(url: str | None) -> Path | None:
    """Download thumbnail to a temp file. Returns path or None."""
    if not url:
        return None
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=15) as r:
            data = r.read()
        if not data:
            return None
        fd, path = tempfile.mkstemp(suffix=".img")
        os.close(fd)
        Path(path).write_bytes(data)
        return Path(path)
    except Exception:
        return None


def render_thumbnail(path: Path | None, width: int = 36, height: int = 12) -> None:
    """Render image in terminal via chafa (kitty protocol, fallback symbols)."""
    if not path or not shutil.which("chafa"):
        return
    for fmt in ("kitty", "symbols"):
        try:
            subprocess.run(
                ["chafa", "--format", fmt, "--size", f"{width}x{height}", str(path)],
                check=False,
            )
            if fmt == "kitty":
                return
            return  # symbols printed, done
        except Exception:
            continue


def stat_line(info: dict) -> str:
    parts = []
    if "view_count" in info and info.get("view_count"):
        parts.append(f"👁 {fmt_count(info['view_count'])} views")
    if "like_count" in info and info.get("like_count"):
        parts.append(f"👍 {fmt_count(info['like_count'])}")
    if "repost_count" in info and info.get("repost_count"):
        parts.append(f"🔁 {fmt_count(info['repost_count'])}")
    elif "share_count" in info and info.get("share_count"):
        parts.append(f"🔁 {fmt_count(info['share_count'])}")
    if "comment_count" in info and info.get("comment_count"):
        parts.append(f"💬 {fmt_count(info['comment_count'])}")
    if "channel_follower_count" in info and info.get("channel_follower_count"):
        parts.append(f"👥 {fmt_count(info['channel_follower_count'])}")
    return "   ".join(parts) if parts else "no engagement stats available"


def render_info(info: dict) -> None:
    site = info.get("extractor_key") or info.get("extractor") or "Unknown"
    print()
    print(f"{C['bold']}{C['cyan']}┌─ {site}{C['reset']}  {C['dim']}{info.get('webpage_url','')}{C['reset']}")
    print(f"{C['bold']}{C['yellow']}│ {info.get('title', '(untitled)')}{C['reset']}")
    uploader = info.get("uploader") or info.get("channel") or "unknown"
    print(f"{C['cyan']}│ by {uploader}{C['reset']}   {C['dim']}📅 {fmt_date(info.get('upload_date'))}   ⏱ {fmt_duration(info.get('duration'))}{C['reset']}")
    print(f"{C['green']}│ {stat_line(info)}{C['reset']}")
    print(f"{C['cyan']}└{'─' * 60}{C['reset']}")
    desc = (info.get("description") or "").strip()
    if desc:
        print(f"{C['dim']}📝 {desc[:500]}{C['reset']}")
        print()


def pick(choices: list[str], prompt: str = "Select") -> str:
    """Picker: fuzzel if available, else stdin. Returns choice or ''."""
    if shutil.which("fuzzel"):
        r = subprocess.run(
            ["fuzzel", "--dmenu", "--minimal-lines", "-p", prompt],
            input="\n".join(choices) + "\n",
            capture_output=True, text=True,
        )
        return r.stdout.strip()
    print()
    for i, c in enumerate(choices, 1):
        print(f"{C['green']}{i:2}){C['reset']} {c}")
    try:
        n = int(input(f"{C['cyan']}➤ {prompt} [1-{len(choices)}]: {C['reset']}").strip())
        if 1 <= n <= len(choices):
            return choices[n - 1]
    except (ValueError, EOFError):
        pass
    return ""


def format_list(info: dict) -> list[str]:
    """Nice format list: [label, format_id] pairs joined."""
    out = []
    seen = set()
    for f in info.get("formats", []):
        fid = str(f.get("format_id", ""))
        note = f.get("format_note", "") or ""
        ext = f.get("ext", "")
        res = f.get("resolution") or ""
        vbr = f.get("vbr")
        abr = f.get("abr")
        size = f.get("filesize") or f.get("filesize_approx")
        label = f"{fid:>5}  {ext:<5} {note:<14} {res:<10} "
        if vbr:
            label += f"v:{vbr:.0f}k"
        if abr:
            label += f" a:{abr:.0f}k"
        if size:
            label += f"  {size/1e6:.1f}MB"
        if (fid, ext) not in seen:
            seen.add((fid, ext))
            out.append(f"{label}\x1f{fid}")
    return out


def pick_format(info: dict, best_id: str) -> str | None:
    choices = format_list(info)
    if not choices:
        return best_id
    sel = pick(choices, "Format")
    if not sel:
        return None
    return sel.split("\x1f")[-1]


def download(url: str, fmt: str | None, mode: str, out_dir: Path,
             title: str = "", site: str = "") -> tuple[bool, str | None]:
    """Download; returns (ok, destination_path)."""
    out_dir.mkdir(parents=True, exist_ok=True)
    ARCHIVE.parent.mkdir(parents=True, exist_ok=True)
    args = [
        "--newline", "--no-mtime", "--embed-metadata", "--no-warnings",
        "--download-archive", str(ARCHIVE),
        "-o", str(out_dir / "%(title).200B [%(id)s].%(ext)s"),
    ]
    if BROWSER_COOKIES:
        args = ["--cookies-from-browser", BROWSER_COOKIES] + args
    if mode == "audio":
        args += ["-x", "--audio-format", "mp3", "--audio-quality", "0"]
    elif fmt and fmt != "best":
        args += ["-f", fmt]
    elif fmt == "best":
        args += ["-f", "bv*+ba/b", "--merge-output-format", "mp4"]
    args.append(url)

    print(f"{C['cyan']}⬇ Downloading…{C['reset']}")
    p = subprocess.Popen(["yt-dlp", *args], stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT, text=True, bufsize=1)
    assert p.stdout is not None
    last = ""
    dests: list[str] = []
    for line in p.stdout:
        line = line.rstrip()
        m = re.search(r"(\d+(?:\.\d+)?)% of", line)
        if m:
            last = f"\r{C['cyan']}⬇ {m.group(1)}%{C['reset']}"
            print(last, end="", flush=True)
        elif "Destination" in line:
            d = line.split("Destination: ", 1)[-1].strip()
            if d:
                dests.append(d)
        elif "has already been downloaded" in line:
            print(f"\n{C['yellow']}✓ already downloaded — skipping{C['reset']}")
    if last:
        print()
    p.wait()
    ok = p.returncode == 0
    dest = _pick_dest(dests, out_dir)
    head = title or (Path(dest).name if dest else "") or "SnowVideoDL"
    body = f"{site} · {mode}" if site else ""
    if dest:
        body = (body + " · " if body else "") + dest
    notify_done(head, body or "Done ✓", dest if ok else None)
    return ok, dest


def _pick_dest(dests: list[str], out_dir: Path) -> str | None:
    """Pick the real output file: first existing destination line, else
    newest media file in out_dir (excluding archive/history)."""
    for d in dests:
        if Path(d).exists():
            return d
    ignore = {ARCHIVE.name, HISTORY.name}
    files = [p for p in out_dir.glob("*") if p.name not in ignore]
    files.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    return str(files[0]) if files else None


def main() -> int:
    args = [a for a in sys.argv[1:]]
    mode = "video"
    show_formats = False
    show_thumb = True
    url = None

    i = 0
    while i < len(args):
        a = args[i]
        if a in ("--audio", "-a"):
            mode = "audio"
        elif a in ("--list-formats", "-f"):
            show_formats = True
        elif a in ("--no-thumb", "-t"):
            show_thumb = False
        elif a in ("--history", "-h"):
            return show_history()
        elif a in ("--help", "-H"):
            print(__doc__)
            return 0
        elif a.startswith("http"):
            url = a
        else:
            print(f"{C['red']}unknown arg: {a}{C['reset']}", file=sys.stderr)
        i += 1

    if not url:
        # clipboard auto-detect (borrowed from ytui)
        clip = clipboard_url()
        if clip:
            choice = pick(
                [f"Use clipboard: {clip[:80]}", "Type URL manually"], "URL source")
            if not choice:
                return 1
            if choice.startswith("Use clipboard"):
                url = clip
        if not url:
            if shutil.which("fuzzel"):
                r = subprocess.run(
                    ["fuzzel", "--dmenu", "--lines=1", "-p", "Video URL: ",
                     "--placeholder", "Ctrl+V / Ctrl+Shift+V to paste"],
                    capture_output=True, text=True,
                )
                url = r.stdout.strip()
            else:
                url = input("Video URL: ").strip()
            if not url:
                return 1

    try:
        info = fetch_metadata(url)
    except Exception as e:
        print(f"{C['red']}✗ Couldn't read video info: {e}{C['reset']}")
        return 1

    if show_thumb:
        thumb = fetch_thumbnail(info.get("thumbnail"))
        render_thumbnail(thumb)
    render_info(info)

    if show_formats:
        best_id = info.get("format_id") or "best"
        fmt = pick_format(info, best_id)
        if not fmt:
            return 1
        mode = "format"
    else:
        fmt = None
        if mode == "audio":
            choice = "Audio only (mp3)"
        else:
            choice = pick(
                ["Best quality (video+audio mp4)", "Audio only (mp3)",
                 "List all formats", "✗ Cancel"],
                "Download",
            )
        if not choice or "Cancel" in choice:
            return 1
        if "Audio only" in choice:
            mode = "audio"
        elif "List all" in choice:
            best_id = info.get("format_id") or "best"
            fmt = pick_format(info, best_id)
            if not fmt:
                return 1
            mode = "format"
        else:
            fmt = "best"
            mode = "video"

    ok, dest = download(url, fmt, mode, DL_DIR,
                        title=info.get("title", ""), site=info.get("extractor_key", ""))
    if ok:
        # record history + offer to open
        add_history({
            "url": url,
            "title": info.get("title", ""),
            "site": info.get("extractor_key", ""),
            "date": fmt_date(info.get("upload_date")),
            "when": datetime.now().strftime("%Y-%m-%d %H:%M"),
            "mode": mode,
            "path": dest or "",
        })
        print(f"{C['green']}✓ Done — {DL_DIR}{C['reset']}")
        if dest and Path(dest).exists():
            act = pick(["▶ Open now", "Open folder", "✗ Close"], "After download")
            if act.startswith("▶"):
                open_media(dest)
            elif act.startswith("Open folder"):
                subprocess.Popen(["xdg-open", str(DL_DIR)], stdout=subprocess.DEVNULL,
                                 stderr=subprocess.DEVNULL)
    else:
        print(f"{C['red']}✗ Failed{C['reset']}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
