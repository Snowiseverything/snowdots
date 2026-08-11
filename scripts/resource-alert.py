#!/usr/bin/env python3
"""Resource alert notifier — polls CPU/RAM/GPU/disk and fires notify-send on threshold breach.

Data sources (all read-only):
  - CPU temp:   lm-sensors (coretemp "Package id 0" / k10temp Tctl/Tdie)
  - CPU usage:  /proc/stat deltas
  - RAM/swap:   /proc/meminfo
  - GPU:        nvidia-smi (temp, util, VRAM)
  - Disk:       statvfs per configured mount

Thresholds + tuning via environment (see DEFAULTS). Runs forever; each metric
alerts at most once per COOLDOWN seconds, with warn -> crit escalation.

Usage:
  resource-alert.py                 # run with defaults
  INTERVAL=10 CPU_TEMP_CRIT=92 ... resource-alert.py
"""

from __future__ import annotations

import json
import os
import subprocess
import time
from pathlib import Path

DEFAULTS = {
    "INTERVAL": 15,            # poll seconds
    "COOLDOWN": 900,           # seconds between alerts per metric (15 min)
    "CPU_TEMP_WARN": 80,
    "CPU_TEMP_CRIT": 90,
    "CPU_USAGE_WARN": 85,
    "CPU_USAGE_CRIT": 95,
    "RAM_WARN": 85,
    "RAM_CRIT": 95,
    "SWAP_WARN": 50,
    "SWAP_CRIT": 75,
    "GPU_TEMP_WARN": 80,
    "GPU_TEMP_CRIT": 90,
    "GPU_VRAM_WARN": 90,
    "GPU_VRAM_CRIT": 97,
    "DISK_WARN": 92,
    "DISK_CRIT": 96,
    "DISK_MOUNTS": "/, /mnt/games, /mnt/data, /mnt/backups",
    "VERBOSE": "0",
}


def cfg_str(name: str) -> str:
    return os.environ.get(name) or str(DEFAULTS[name])


def cfg_int(name: str) -> int:
    try:
        return int(cfg_str(name))
    except ValueError:
        return int(DEFAULTS[name])


def notify(metric: str, severity: str, title: str, body: str) -> None:
    urgency = "critical" if severity == "crit" else "normal"
    try:
        subprocess.run(
            ["notify-send", "-a", "resource-alert", "-u", urgency, "-i", "dialog-warning",
             title, body],
            check=False, timeout=5,
        )
    except Exception:
        pass  # never let notify failure kill the loop
    if cfg_int("VERBOSE") > 0:
        print(f"[{metric}] {severity}: {title} — {body}", flush=True)


def read_proc_stat() -> dict:
    total = idle = 0
    try:
        with open("/proc/stat") as f:
            first = f.readline().split()
        if first and first[0] == "cpu":
            vals = [int(x) for x in first[1:9]]
            idle = vals[3] + (vals[4] if len(vals) > 4 else 0)
            total = sum(vals)
    except Exception:
        pass
    return {"total": total, "idle": idle}


def cpu_usage() -> float:
    """Percent busy over one INTERVAL sample window (first call returns 0)."""
    if not hasattr(cpu_usage, "prev"):
        cpu_usage.prev = read_proc_stat()  # type: ignore[attr-defined]
        return 0.0
    cur = read_proc_stat()
    prev = cpu_usage.prev  # type: ignore[attr-defined]
    cpu_usage.prev = cur  # type: ignore[attr-defined]
    t = cur["total"] - prev["total"]
    i = cur["idle"] - prev["idle"]
    return 0.0 if t <= 0 else (1.0 - i / t) * 100.0


def cpu_temp() -> float:
    """Package temperature in °C via `sensors -j`. Returns 0 on failure."""
    try:
        out = subprocess.run(["sensors", "-j"], capture_output=True, text=True, timeout=5)
        if out.returncode != 0:
            return 0.0
        data = json.loads(out.stdout or "{}")
        for chip in data.values():
            if not isinstance(chip, dict):
                continue
            for key in ("Package id 0", "Tctl", "Tdie", "Tccd1", "Tccd2"):
                sub = chip.get(key)
                if isinstance(sub, dict) and "temp1_input" in sub:
                    try:
                        return float(sub["temp1_input"])
                    except (TypeError, ValueError):
                        continue
    except Exception:
        pass
    return 0.0


def meminfo() -> dict:
    info = {}
    try:
        with open("/proc/meminfo") as f:
            for line in f:
                parts = line.split()
                if len(parts) >= 2 and parts[0].endswith(":"):
                    info[parts[0][:-1]] = int(parts[1])
    except Exception:
        pass
    return info


def gpu_stats() -> dict:
    """Temp, util%, VRAM used/total MiB. Empty dict when nvidia-smi absent."""
    try:
        out = subprocess.run(
            ["nvidia-smi", "--query-gpu=temperature.gpu,utilization.gpu,memory.used,memory.total",
             "--format=csv,noheader,nounits"],
            capture_output=True, text=True, timeout=5,
        )
        if out.returncode != 0:
            return {}
        parts = [p.strip() for p in (out.stdout or "").strip().split(",")]
        if len(parts) < 4:
            return {}
        return {
            "temp": float(parts[0]),
            "util": float(parts[1]),
            "vram_used": float(parts[2]),
            "vram_total": float(parts[3]),
        }
    except Exception:
        return {}


def disk_usage(mount: str) -> float:
    try:
        st = os.statvfs(mount)
        total = st.f_blocks * st.f_frsize
        free = st.f_bavail * st.f_frsize
        if total <= 0:
            return 0.0
        return (1.0 - free / total) * 100.0
    except Exception:
        return 0.0


def main() -> None:
    interval = cfg_int("INTERVAL")
    cooldown = cfg_int("COOLDOWN")
    mounts = [m.strip() for m in cfg_str("DISK_MOUNTS").split(",") if m.strip()]
    verbose = cfg_int("VERBOSE")

    # metric -> (warn, crit, last_alert_time)
    rules = {
        "CPU temp": (cfg_int("CPU_TEMP_WARN"), cfg_int("CPU_TEMP_CRIT"), 0.0),
        "CPU usage": (cfg_int("CPU_USAGE_WARN"), cfg_int("CPU_USAGE_CRIT"), 0.0),
        "RAM": (cfg_int("RAM_WARN"), cfg_int("RAM_CRIT"), 0.0),
        "Swap": (cfg_int("SWAP_WARN"), cfg_int("SWAP_CRIT"), 0.0),
        "GPU temp": (cfg_int("GPU_TEMP_WARN"), cfg_int("GPU_TEMP_CRIT"), 0.0),
        "GPU VRAM": (cfg_int("GPU_VRAM_WARN"), cfg_int("GPU_VRAM_CRIT"), 0.0),
    }
    for m in mounts:
        rules[f"Disk {m}"] = (cfg_int("DISK_WARN"), cfg_int("DISK_CRIT"), 0.0)

    if verbose:
        print("resource-alert starting: interval", interval, "cooldown", cooldown, flush=True)

    cpu_usage()  # seed baseline

    while True:
        now = time.time()
        readings = {
            "CPU temp": cpu_temp(),
            "CPU usage": cpu_usage(),
            "RAM": 0.0,
            "Swap": 0.0,
            "GPU temp": 0.0,
            "GPU VRAM": 0.0,
        }

        info = meminfo()
        mem_total = info.get("MemTotal", 0)
        mem_avail = info.get("MemAvailable", 0)
        if mem_total:
            readings["RAM"] = (1.0 - mem_avail / mem_total) * 100.0
        swap_total = info.get("SwapTotal", 0)
        swap_free = info.get("SwapFree", 0)
        if swap_total:
            readings["Swap"] = (1.0 - swap_free / swap_total) * 100.0

        gpu = gpu_stats()
        if gpu:
            readings["GPU temp"] = gpu["temp"]
            if gpu["vram_total"]:
                readings["GPU VRAM"] = gpu["vram_used"] / gpu["vram_total"] * 100.0

        for m in mounts:
            readings[f"Disk {m}"] = disk_usage(m)

        for metric, (warn, crit, last) in list(rules.items()):
            value = readings.get(metric, 0.0)
            severity = "crit" if value >= crit else ("warn" if value >= warn else "")
            if not severity:
                continue
            if now - last < cooldown:
                continue

            unit = "°C" if "temp" in metric or metric == "Swap" else "%"
            if metric == "GPU VRAM":
                v = f"{value:.0f}% ({(gpu or {}).get('vram_used', 0):.0f}/{ (gpu or {}).get('vram_total', 0):.0f} MiB)"
            elif metric.startswith("Disk "):
                v = f"{value:.0f}%"
            elif "temp" in metric:
                v = f"{value:.0f}{unit}"
            else:
                v = f"{value:.0f}%"

            level = "critical" if severity == "crit" else "high"
            notify(
                metric, severity,
                f"{metric} {level}",
                f"{metric} at {v} (warn {warn} / crit {crit})",
            )
            rules[metric] = (warn, crit, now)

        time.sleep(interval)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
