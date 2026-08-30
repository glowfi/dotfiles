pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: sysMon

    // ================= system monitor =================
    property real cpuPct: 0
    property real cpuMhz: -1
    property real memPct: 0
    property real memUsedG: 0
    property real memTotalG: 0
    property real diskPct: 0
    property string diskUsed: "--"
    property string diskAvail: "--"
    property int gpuPct: -1          // -1 = no readable GPU, row hides
    property real gpuMemUsed: -1     // GiB
    property real gpuMemTotal: -1
    property real netRx: 0           // bytes/s
    property real netTx: 0
    property var _cpuPrev: null
    property var _netPrev: null
    property double _netStamp: 0

    function fmtRate(b) {
        if (b >= 1048576) return (b / 1048576).toFixed(1) + " MB/s";
        if (b >= 1024)    return (b / 1024).toFixed(0) + " KB/s";
        return Math.round(b) + " B/s";
    }
    function fmtRateShort(b) {
        if (b >= 1048576) return (b / 1048576).toFixed(1) + "M";
        if (b >= 1024)    return (b / 1024).toFixed(0) + "K";
        return Math.round(b) + "B";
    }

    Process {
        id: sysPoll
        command: ["sh", "-c",
            "head -1 /proc/stat; echo @@; " +
            "grep -E 'MemTotal|MemAvailable' /proc/meminfo; echo @@; " +
            "cat /proc/net/dev; echo @@; " +
            "df -Ph / | tail -1; echo @@; " +
            "cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -1 " +
            "|| nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null " +
            "|| echo -1; echo @@; " +
            "awk '/cpu MHz/ {s+=$4; n++} END {print (n>0) ? s/n : -1}' /proc/cpuinfo; echo @@; " +
            "v=$(cat /sys/class/drm/card*/device/mem_info_vram_used 2>/dev/null | head -1); " +
            "t=$(cat /sys/class/drm/card*/device/mem_info_vram_total 2>/dev/null | head -1); " +
            "if [ -n \"$v\" ] && [ -n \"$t\" ]; then echo amd $v $t; " +
            "else o=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | head -1 | awk -F', *' '{print \"nv\", $1, $2}'); " +
            "[ -n \"$o\" ] && echo $o || echo none; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const sec = text.split("@@");
                if (sec.length < 5) return;

                // --- cpu: jiffies delta from /proc/stat ---
                const c = sec[0].trim().split(/\s+/).slice(1).map(Number);
                const idle = c[3] + (c[4] || 0);
                const total = c.reduce((a, b) => a + b, 0);
                if (sysMon._cpuPrev) {
                    const dt = total - sysMon._cpuPrev.total;
                    const di = idle - sysMon._cpuPrev.idle;
                    if (dt > 0) cpuPct = Math.max(0, Math.min(100, 100 * (1 - di / dt)));
                }
                sysMon._cpuPrev = { total: total, idle: idle };

                // --- ram ---
                const mt = /MemTotal:\s+(\d+)/.exec(sec[1]);
                const ma = /MemAvailable:\s+(\d+)/.exec(sec[1]);
                if (mt && ma) {
                    const total = parseInt(mt[1]), avail = parseInt(ma[1]);
                    memPct = 100 * (1 - avail / total);
                    memTotalG = total / 1048576;
                    memUsedG = (total - avail) / 1048576;
                }

                // --- network: rx/tx byte deltas, all ifaces except lo ---
                let rx = 0, tx = 0;
                for (const line of sec[2].split("\n")) {
                    const m = /^\s*(\S+):\s*(.*)$/.exec(line);
                    if (!m || m[1] === "lo") continue;
                    const f = m[2].trim().split(/\s+/).map(Number);
                    rx += f[0]; tx += f[8];
                }
                const now = Date.now();
                if (sysMon._netPrev && now > sysMon._netStamp) {
                    const dt = (now - sysMon._netStamp) / 1000;
                    netRx = Math.max(0, (rx - sysMon._netPrev.rx) / dt);
                    netTx = Math.max(0, (tx - sysMon._netPrev.tx) / dt);
                }
                sysMon._netPrev = { rx: rx, tx: tx };
                sysMon._netStamp = now;

                // --- disk / (df -Ph: fs size used avail use% mount) ---
                const df = sec[3].trim().split(/\s+/);
                if (df.length >= 5) {
                    diskUsed = df[2];
                    diskAvail = df[3];
                    diskPct = parseInt(df[4]) || 0;
                }

                // --- gpu ---
                const g = parseInt(sec[4].trim());
                gpuPct = isNaN(g) ? -1 : g;

                // --- cpu freq (avg MHz) ---
                if (sec.length > 5) {
                    const f = parseFloat(sec[5].trim());
                    cpuMhz = isNaN(f) ? -1 : f;
                }

                // --- gpu vram (amd: bytes, nvidia: MiB) ---
                if (sec.length > 6) {
                    const gp = sec[6].trim().split(/\s+/);
                    if (gp[0] === "amd" && gp.length >= 3) {
                        gpuMemUsed = parseInt(gp[1]) / 1073741824;
                        gpuMemTotal = parseInt(gp[2]) / 1073741824;
                    } else if (gp[0] === "nv" && gp.length >= 3) {
                        gpuMemUsed = parseInt(gp[1]) / 1024;
                        gpuMemTotal = parseInt(gp[2]) / 1024;
                    } else {
                        gpuMemUsed = -1;
                        gpuMemTotal = -1;
                    }
                }
            }
        }
    }
    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: sysPoll.running = true
    }
}
