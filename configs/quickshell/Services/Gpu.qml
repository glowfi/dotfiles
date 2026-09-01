pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// GPU enumeration + per-card monitoring. AMD/Intel via sysfs, NVIDIA via
// nvidia-smi. `selected` picks which card the bar pill reports.
Singleton {
    id: gpu

    property var gpus: []        // { card, vendor, name, busy, vramUsed, vramTotal }
    property int selected: 0

    readonly property var sel: gpus.length > selected ? gpus[selected] : null

    // GiB in, honest string out: sub-GiB cards show MiB, no fake rounding
    function fmtG(v) {
        if (v < 1) return Math.round(v * 1024) + "M";
        return (v >= 10 ? v.toFixed(0) : v.toFixed(1)) + "G";
    }

    function vendorName(v) {
        if (v === "0x1002") return "AMD";
        if (v === "0x10de") return "NVIDIA";
        if (v === "0x8086") return "Intel";
        return "GPU";
    }

    Process {
        id: gpuPoll
        command: ["sh", "-c",
            "for c in /sys/class/drm/card[0-9]; do " +
            "  [ -e \"$c/device/vendor\" ] || continue; " +
            "  d=$c/device; " +
            "  v=$(cat $d/vendor 2>/dev/null); " +
            "  b=$(cat $d/gpu_busy_percent 2>/dev/null || echo -1); " +
            "  vu=$(cat $d/mem_info_vram_used 2>/dev/null || echo -1); " +
            "  vt=$(cat $d/mem_info_vram_total 2>/dev/null || echo -1); " +
            "  a=$(basename $(readlink -f $d)); " +
            "  n=$(lspci -mm -s $a 2>/dev/null | awk -F'\"' '{print $6}'); " +
            "  echo \"$(basename $c) $v $b $vu $vt|$n\"; " +
            "done; " +
            "nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total " +
            "--format=csv,noheader,nounits 2>/dev/null | head -1 | awk -F', *' '{print \"NV\", $1, $2, $3}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                let nv = null;
                for (const line of text.split("\n")) {
                    const parts = line.split("|");
                    const p = parts[0].trim().split(/\s+/);
                    if (p[0] === "NV" && p.length >= 4) {
                        nv = { busy: parseInt(p[1]), vramUsed: parseInt(p[2]) / 1024,
                               vramTotal: parseInt(p[3]) / 1024 };
                        continue;
                    }
                    if (p.length < 5) continue;
                    const pretty = (parts[1] ?? "").trim();
                    out.push({
                        card: p[0],
                        vendor: p[1],
                        name: pretty !== "" ? pretty
                              : gpu.vendorName(p[1]) + " (" + p[0] + ")",
                        busy: parseInt(p[2]),
                        vramUsed: parseInt(p[3]) > 0 ? parseInt(p[3]) / 1073741824 : -1,
                        vramTotal: parseInt(p[4]) > 0 ? parseInt(p[4]) / 1073741824 : -1
                    });
                }
                // fold nvidia-smi numbers into the 0x10de card (its sysfs reports nothing)
                if (nv) for (const g of out) {
                    if (g.vendor === "0x10de") {
                        g.busy = nv.busy;
                        g.vramUsed = nv.vramUsed;
                        g.vramTotal = nv.vramTotal;
                    }
                }
                gpu.gpus = out;
                if (gpu.selected >= out.length) gpu.selected = 0;
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: gpuPoll.running = true }
}
