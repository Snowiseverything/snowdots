pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config

Singleton {
    id: root

    // CPU properties
    property string cpuName: ""
    property real cpuPerc
    property real cpuTemp

    // Extended CPU data
    property var perCorePerc: []       // usage 0..1 per core
    property real cpuFreqMhz: 0       // current average frequency
    property real loadAvg1: 0
    property real loadAvg5: 0
    property real loadAvg15: 0
    property int coreCount: 0

    // GPU properties
    readonly property string gpuType: GlobalConfig.services.gpuType.toUpperCase() || autoGpuType
    property string autoGpuType: "NONE"
    property string gpuName: ""
    property real gpuPerc
    property real gpuTemp

    // Extended GPU data
    property real gpuClockSm: 0        // MHz
    property real gpuClockMem: 0       // MHz
    property real gpuPower: 0          // W
    property real gpuVramUsed: 0       // MiB
    property real gpuVramTotal: 0      // MiB
    property real gpuFan: 0            // %

    // Memory properties
    property real memUsed
    property real memTotal
    readonly property real memPerc: memTotal > 0 ? memUsed / memTotal : 0
    property real memAvailable
    property real memCached
    // RAM speed: env QS_RAM_SPEED_MHZ wins, falls back to config file
    // ~/.config/quickshell/caelestia/ram-speed (live-editable, no restart needed)
    property int ramSpeedFileValue: 0
    readonly property real ramSpeedMhz: {
        const fromEnv = parseInt(Quickshell.env("QS_RAM_SPEED_MHZ") ?? "0", 10);
        if (Number.isFinite(fromEnv) && fromEnv > 0)
            return fromEnv;
        return ramSpeedFileValue;
    }

    // System info (static — loaded once, no root needed)
    property string sysVendor: ""
    property string sysProduct: ""
    property string moboVendor: ""
    property string moboName: ""
    property int cpuBaseMhz: 0
    property int cpuMaxMhz: 0
    property int cpuPhysicalCores: 0
    property string gpuDriver: ""
    // CPU power estimate (W) — RAPL energy_uj is root-only on this system,
    // so we estimate from utilization + the readable RAPL max power limit.
    readonly property real cpuPowerW: {
        const idleW = 8; // i7-12700KF idle baseline
        const maxW = 125; // package-0 constraint_0_max_power_uw = 125000000 µW
        if (cpuPerc <= 0) return idleW;
        return idleW + cpuPerc * (maxW - idleW);
    }

    // Swap properties
    property real swapUsed
    property real swapTotal
    readonly property real swapPerc: swapTotal > 0 ? swapUsed / swapTotal : 0

    // Storage properties (aggregated)
    readonly property real storagePerc: {
        let totalUsed = 0;
        let totalSize = 0;
        for (const disk of disks) {
            totalUsed += disk.used;
            totalSize += disk.total;
        }
        return totalSize > 0 ? totalUsed / totalSize : 0;
    }

    // Individual disks: Array of { mount, used, total, free, perc }
    property var disks: []

    property real lastCpuIdle
    property real lastCpuTotal
    property var lastPerCoreTotal: []   // previous per-core busy+idle sums
    property var lastPerCoreIdle: []

    property int refCount

    function cleanCpuName(name: string): string {
        return name.replace(/\(R\)|\(TM\)|CPU|\d+(?:th|nd|rd|st) Gen |Core |Processor/gi, "").replace(/\s+/g, " ").trim();
    }

    function cleanGpuName(name: string): string {
        return name.replace(/\(R\)|\(TM\)|Graphics/gi, "").replace(/\s+/g, " ").trim();
    }

    function formatKib(kib: real): var {
        const mib = 1024;
        const gib = 1024 ** 2;
        const tib = 1024 ** 3;

        if (kib >= tib)
            return {
                value: kib / tib,
                unit: "TiB"
            };
        if (kib >= gib)
            return {
                value: kib / gib,
                unit: "GiB"
            };
        if (kib >= mib)
            return {
                value: kib / mib,
                unit: "MiB"
            };
        return {
            value: kib,
            unit: "KiB"
        };
    }

    Timer {
        running: root.refCount > 0
        interval: GlobalConfig.dashboard.resourceUpdateInterval
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            loadavg.reload();
            cpuinfoFreq.reload();
            storage.running = true;
            gpuUsage.running = true;
            gpuDetail.running = true;
            sensors.running = true;
            ramSpeedFile.reload();
        }
    }

    // RAM speed config file (live-editable: ~/.config/quickshell/caelestia/ram-speed)
    FileView {
        id: ramSpeedFile

        path: `${Quickshell.env("HOME")}/.config/quickshell/caelestia/ram-speed`
        onLoaded: {
            const v = parseInt(text().trim(), 10);
            root.ramSpeedFileValue = Number.isFinite(v) && v > 0 ? v : 0;
        }
    }

    // --- Static system info (no root needed) ---
    FileView {
        path: "/sys/class/dmi/id/sys_vendor"
        onLoaded: root.sysVendor = text().trim()
    }

    FileView {
        path: "/sys/class/dmi/id/product_name"
        onLoaded: root.sysProduct = text().trim()
    }

    FileView {
        path: "/sys/class/dmi/id/board_vendor"
        onLoaded: root.moboVendor = text().trim()
    }

    FileView {
        path: "/sys/class/dmi/id/board_name"
        onLoaded: root.moboName = text().trim()
    }

    FileView {
        path: "/sys/devices/system/cpu/cpu0/cpufreq/base_frequency"
        onLoaded: {
            const khz = parseInt(text().trim(), 10);
            root.cpuBaseMhz = Number.isFinite(khz) && khz > 0 ? Math.round(khz / 1000) : 0;
        }
    }

    FileView {
        path: "/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq"
        onLoaded: {
            const khz = parseInt(text().trim(), 10);
            root.cpuMaxMhz = Number.isFinite(khz) && khz > 0 ? Math.round(khz / 1000) : 0;
        }
    }

    Process {
        id: cpuTopology

        running: true
        command: ["sh", "-c", "cat /sys/devices/system/cpu/cpu*/topology/core_id 2>/dev/null | sort -un | wc -l"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseInt(text.trim(), 10);
                root.cpuPhysicalCores = Number.isFinite(n) && n > 0 ? n : 0;
            }
        }
    }

    // One-time CPU info detection (name)
    FileView {
        id: cpuinfoInit

        path: "/proc/cpuinfo"
        onLoaded: {
            const nameMatch = text().match(/model name\s*:\s*(.+)/);
            if (nameMatch)
                root.cpuName = root.cleanCpuName(nameMatch[1]);
        }
    }

    FileView {
        id: stat

        path: "/proc/stat"
        onLoaded: {
            const lines = text().split("\n");
            const first = lines[0].match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/);
            if (first) {
                const stats = first.slice(1).map(n => parseInt(n, 10));
                const total = stats.reduce((a, b) => a + b, 0);
                const idle = stats[3] + (stats[4] ?? 0);

                const totalDiff = total - root.lastCpuTotal;
                const idleDiff = idle - root.lastCpuIdle;
                root.cpuPerc = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0;

                root.lastCpuTotal = total;
                root.lastCpuIdle = idle;
            }

            // Per-core usage: cpu0..cpuN lines
            const perCore = [];
            const totals = [];
            const idles = [];
            for (const line of lines) {
                const m = line.match(/^cpu(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/);
                if (!m)
                    continue;
                const idx = parseInt(m[1], 10);
                const s = m.slice(2).map(n => parseInt(n, 10));
                const t = s.reduce((a, b) => a + b, 0);
                totals[idx] = t;
                idles[idx] = s[3] + (s[4] ?? 0);
                const prevTotal = (root.lastPerCoreTotal[idx] ?? 0);
                const prevIdle = (root.lastPerCoreIdle[idx] ?? 0);
                const tDiff = t - prevTotal;
                const iDiff = idles[idx] - prevIdle;
                perCore[idx] = tDiff > 0 ? Math.max(0, Math.min(1, 1 - iDiff / tDiff)) : 0;
            }
            root.perCorePerc = perCore;
            root.lastPerCoreTotal = totals;
            root.lastPerCoreIdle = idles;
            root.coreCount = perCore.length;
        }
    }

    FileView {
        id: loadavg

        path: "/proc/loadavg"
        onLoaded: {
            const parts = text().trim().split(/\s+/);
            root.loadAvg1 = parseFloat(parts[0] ?? 0);
            root.loadAvg5 = parseFloat(parts[1] ?? 0);
            root.loadAvg15 = parseFloat(parts[2] ?? 0);
        }
    }

    FileView {
        id: cpuinfoFreq

        path: "/proc/cpuinfo"
        onLoaded: {
            const mhz = [];
            for (const line of text().split("\n")) {
                const m = line.match(/cpu MHz\s*:\s*([0-9.]+)/);
                if (m)
                    mhz.push(parseFloat(m[1]));
            }
            if (mhz.length) {
                root.cpuFreqMhz = mhz.reduce((a, b) => a + b, 0) / mhz.length;
            }
        }
    }

    FileView {
        id: meminfo

        path: "/proc/meminfo"
        onLoaded: {
            const data = text();
            const avail = parseInt(data.match(/MemAvailable: *(\d+)/)[1], 10) || 0;
            const cached = (parseInt(data.match(/^Cached: *(\d+)/m)[1], 10) || 0) + (parseInt(data.match(/^SReclaimable: *(\d+)/m)[1], 10) || 0);
            root.memAvailable = avail;
            root.memCached = cached;
            root.memTotal = parseInt(data.match(/MemTotal: *(\d+)/)[1], 10) || 1;
            root.memUsed = (root.memTotal - avail) || 0;
            root.swapTotal = parseInt(data.match(/SwapTotal: *(\d+)/)[1], 10) || 0;
            root.swapUsed = (root.swapTotal - parseInt(data.match(/SwapFree: *(\d+)/)[1], 10)) || 0;
        }
    }

    Process {
        id: storage

        // Get physical disks with aggregated usage from their partitions
        // -J triggers JSON output. -b triggers bytes.
        command: ["lsblk", "-J", "-b", "-o", "NAME,SIZE,TYPE,FSUSED,FSSIZE,MOUNTPOINT"]

        stdout: StdioCollector {
            onStreamFinished: {
                const data = JSON.parse(text);
                const diskList = [];
                const seenDevices = new Set();

                // Helper to recursively sum usage from children (partitions, crypt, lvm)
                const aggregateUsage = dev => {
                    let used = 0;
                    let size = 0;
                    let isRoot = dev.mountpoint === "/" || (dev.mountpoints && dev.mountpoints.includes("/"));

                    if (!seenDevices.has(dev.name)) {
                        // lsblk returns null for empty/unformatted partitions, which parses to 0 here
                        used = parseInt(dev.fsused) || 0;
                        size = parseInt(dev.fssize) || 0;
                        seenDevices.add(dev.name);
                    }

                    if (dev.children) {
                        for (const child of dev.children) {
                            const stats = aggregateUsage(child);
                            used += stats.used;
                            size += stats.size;
                            if (stats.isRoot)
                                isRoot = true;
                        }
                    }
                    return {
                        used,
                        size,
                        isRoot
                    };
                };

                for (const dev of data.blockdevices) {
                    // Only process physical disks at the top level
                    if (dev.type === "disk" && !dev.name.startsWith("zram")) {
                        const stats = aggregateUsage(dev);

                        if (stats.size === 0) {
                            continue;
                        }

                        const total = stats.size;
                        const used = stats.used;

                        diskList.push({
                            mount: dev.name,
                            used: used / 1024      // KiB
                            ,
                            total: total / 1024    // KiB
                            ,
                            free: (total - used) / 1024,
                            perc: total > 0 ? used / total : 0,
                            hasRoot: stats.isRoot
                        });
                    }
                }

                // Sort by putting the disk with root first, then sort the rest alphabetically
                root.disks = diskList.sort((a, b) => {
                    if (a.hasRoot && !b.hasRoot)
                        return -1;
                    if (!a.hasRoot && b.hasRoot)
                        return 1;
                    return a.mount.localeCompare(b.mount);
                });
            }
        }
    }

    // GPU name detection (one-time)
    Process {
        id: gpuNameDetect

        running: true
        command: ["sh", "-c", "nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || glxinfo -B 2>/dev/null | grep 'Device:' | cut -d':' -f2 | cut -d'(' -f1 || lspci 2>/dev/null | grep -i 'vga\\|3d controller\\|display' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (!output)
                    return;

                // Check if it's from nvidia-smi (clean GPU name)
                if (output.toLowerCase().includes("nvidia") || output.toLowerCase().includes("geforce") || output.toLowerCase().includes("rtx") || output.toLowerCase().includes("gtx")) {
                    root.gpuName = root.cleanGpuName(output);
                } else if (output.toLowerCase().includes("rx")) {
                    root.gpuName = root.cleanGpuName(output);
                } else {
                    // Parse lspci output: extract name from brackets or after colon
                    // Handles cases like [AMD/ATI] Navi 21 [Radeon RX 6800/6800 XT / 6900 XT] (rev c0)
                    const bracketMatch = output.match(/\[([^\]]+)\][^\[]*$/);
                    if (bracketMatch) {
                        root.gpuName = root.cleanGpuName(bracketMatch[1]);
                    } else {
                        const colonMatch = output.match(/:\s*(.+)/);
                        if (colonMatch)
                            root.gpuName = root.cleanGpuName(colonMatch[1]);
                    }
                }
            }
        }
    }

    Process {
        id: gpuTypeCheck

        running: !GlobalConfig.services.gpuType
        command: ["sh", "-c", "if command -v nvidia-smi &>/dev/null && nvidia-smi -L &>/dev/null; then echo NVIDIA; elif ls /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | grep -q .; then echo GENERIC; else echo NONE; fi"]
        stdout: StdioCollector {
            onStreamFinished: root.autoGpuType = text.trim()
        }
    }

    Process {
        id: gpuUsage

        command: root.gpuType === "GENERIC" ? ["sh", "-c", "cat /sys/class/drm/card*/device/gpu_busy_percent"] : root.gpuType === "NVIDIA" ? ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu", "--format=csv,noheader,nounits"] : ["echo"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.gpuType === "GENERIC") {
                    const percs = text.trim().split("\n");
                    const sum = percs.reduce((acc, d) => acc + parseInt(d, 10), 0);
                    root.gpuPerc = sum / percs.length / 100;
                } else if (root.gpuType === "NVIDIA") {
                    const [usage, temp] = text.trim().split(",");
                    root.gpuPerc = parseInt(usage, 10) / 100;
                    root.gpuTemp = parseInt(temp, 10);
                } else {
                    root.gpuPerc = 0;
                    root.gpuTemp = 0;
                }
            }
        }
    }

    // GPU clocks, power, VRAM, fan, driver (NVIDIA)
    Process {
        id: gpuDetail

        command: root.gpuType === "NVIDIA" ? ["nvidia-smi", "--query-gpu=clocks.sm,clocks.mem,power.draw,memory.used,memory.total,fan.speed,driver_version", "--format=csv,noheader,nounits"] : ["echo"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.gpuType !== "NVIDIA")
                    return;
                const parts = text.trim().split(",").map(s => s.trim());
                root.gpuClockSm = parseFloat(parts[0]) || 0;
                root.gpuClockMem = parseFloat(parts[1]) || 0;
                root.gpuPower = parseFloat(parts[2]) || 0;
                root.gpuVramUsed = parseFloat(parts[3]) || 0;
                root.gpuVramTotal = parseFloat(parts[4]) || 0;
                root.gpuFan = parseFloat(parts[5]) || 0;
                root.gpuDriver = parts[6] || "";
            }
        }
    }

    Process {
        id: sensors

        command: ["sensors"]
        environment: ({
                LANG: "C.UTF-8",
                LC_ALL: "C.UTF-8"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                let cpuTemp = text.match(/(?:Package id [0-9]+|Tdie):\s+((\+|-)[0-9.]+)(°| )C/);
                if (!cpuTemp)
                    // If AMD Tdie pattern failed, try fallback on Tctl
                    cpuTemp = text.match(/Tctl:\s+((\+|-)[0-9.]+)(°| )C/);

                if (cpuTemp)
                    root.cpuTemp = parseFloat(cpuTemp[1]);

                if (root.gpuType !== "GENERIC")
                    return;

                let eligible = false;
                let sum = 0;
                let count = 0;

                for (const line of text.trim().split("\n")) {
                    if (line === "Adapter: PCI adapter")
                        eligible = true;
                    else if (line === "")
                        eligible = false;
                    else if (eligible) {
                        let match = line.match(/^(temp[0-9]+|GPU core|edge)+:\s+\+([0-9]+\.[0-9]+)(°| )C/);
                        if (!match)
                            // Fall back to junction/mem if GPU doesn't have edge temp (for AMD GPUs)
                            match = line.match(/^(junction|mem)+:\s+\+([0-9]+\.[0-9]+)(°| )C/);

                        if (match) {
                            sum += parseFloat(match[2]);
                            count++;
                        }
                    }
                }

                root.gpuTemp = count > 0 ? sum / count : 0;
            }
        }
    }
}
