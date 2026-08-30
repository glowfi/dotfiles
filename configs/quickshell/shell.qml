//@ pragma IconTheme Papirus-Dark
// ~/.config/quickshell/shell.qml
// KDE-Plasma-like panel for MangoWM — gruvbox dark, everything in-shell.
//
// Needs: quickshell >= 0.3.0, mango with socket IPC (mmsg get/watch/dispatch),
//        a Nerd Font. Backend CLIs (no windows spawned): nmcli, cliphist,
//        wl-copy, wlsunset, brightnessctl.
//
// In-shell features:
//   app launcher w/ search • tag switcher • layout picker (all 14 mango
//   layouts) • taskbar • system tray • quick settings (volume/mic/brightness
//   sliders, wifi list+connect, bluetooth devices, night light, power
//   profiles) • notification daemon + history center • clipboard history •
//   calendar • power menu • keyboard layout • overview button

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Services.SystemTray
import Quickshell.Services.Notifications
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

ShellRoot {
    id: root

    // ================= gruvbox dark =================
    readonly property color bg0:    "#282828"
    readonly property color bg0h:   "#1d2021"
    readonly property color bg1:    "#3c3836"
    readonly property color bg2:    "#504945"
    readonly property color bg3:    "#665c54"
    readonly property color fg0:    "#fbf1c7"
    readonly property color fg:     "#ebdbb2"
    readonly property color fgDim:  "#a89984"
    readonly property color gray:   "#928374"
    readonly property color red:    "#fb4934"
    readonly property color green:  "#b8bb26"
    readonly property color yellow: "#fabd2f"
    readonly property color blue:   "#83a598"
    readonly property color purple: "#d3869b"
    readonly property color aqua:   "#8ec07c"
    readonly property color orange: "#fe8019"

    readonly property string fontFamily: "Fantasque Sans Mono"
    property int fontSize: 17
    readonly property int iconSize: fontSize + 9

    function setFontSize(v) {
        fontSize = Math.max(12, Math.min(24, v));
        Quickshell.execDetached(["sh", "-c",
            'mkdir -p "$HOME/.config/mango" && printf %s "$1" > "$HOME/.config/mango/shell-ui.json"',
            "_", JSON.stringify({ fontSize: fontSize })]);
    }
    Process {
        id: uiLoad
        command: ["sh", "-c", 'cat "$HOME/.config/mango/shell-ui.json" 2>/dev/null || echo "{}"']
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const u = JSON.parse(text.trim() || "{}");
                    if (u.fontSize) root.fontSize = Math.max(12, Math.min(24, u.fontSize));
                } catch (e) {}
            }
        }
    }
    readonly property int barHeight: 44

    // ================= mango IPC =================
    // mango layouts: config name -> bar glyph (symbol comes from mango itself)
    readonly property var mangoLayouts: [
        { name: "tile",              sym: "T"  },
        { name: "scroller",          sym: "S"  },
        { name: "grid",              sym: "G"  },
        { name: "monocle",           sym: "M"  },
        { name: "deck",              sym: "K"  },
        { name: "center_tile",       sym: "CT" },
        { name: "right_tile",        sym: "RT" },
        { name: "vertical_scroller", sym: "VS" },
        { name: "vertical_tile",     sym: "VT" },
        { name: "vertical_grid",     sym: "VG" },
        { name: "vertical_deck",     sym: "VK" },
        { name: "dwindle",           sym: "DW" },
        { name: "fair",              sym: "F"  },
        { name: "vertical_fair",     sym: "VF" }
    ]

    function dispatch(cmd) {
        // mmsg replies with JSON; surface failures as a toast instead of
        // discarding them (execDetached would swallow the error silently)
        Quickshell.execDetached(["sh", "-c",
            "out=$(mmsg dispatch \"$1\" 2>&1); case \"$out\" in *error*) " +
            "notify-send 'mango dispatch failed' \"$1 -> $out\";; esac",
            "_", cmd]);
    }

    // ================= night light (wlsunset) =================
    property bool nightLight: false
    Process {
        id: nlCheck
        command: ["sh", "-c", "pgrep -x wlsunset >/dev/null && echo on || echo off"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.nightLight = text.trim() === "on" }
    }
    function toggleNightLight() {
        Quickshell.execDetached(["sh", "-c",
            "pgrep -x wlsunset >/dev/null && pkill -x wlsunset || setsid -f wlsunset -t 4000 -T 6500"]);
        nlRecheck.start();
    }
    Timer { id: nlRecheck; interval: 400; onTriggered: nlCheck.running = true }

    // ================= brightness (brightnessctl) =================
    property int brightness: -1
    Process {
        id: briGet
        command: ["sh", "-c", "brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d %"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.brightness = text.trim() === "" ? -1 : parseInt(text.trim())
        }
    }
    property int briPending: -1
    Process {
        id: briSet
        command: ["sh", "-c", "brightnessctl set " + root.briPending + "% >/dev/null 2>&1"]
        onExited: briGet.running = true
    }
    function adjustFromWheel(delta) {
        if (brightness >= 0) setBrightness(brightness + (delta > 0 ? 5 : -5));
    }
    function setBrightness(pct) {
        briPending = Math.max(1, Math.min(100, Math.round(pct)));
        briApply.restart();
    }
    Timer { id: briApply; interval: 120; onTriggered: briSet.running = true }

    // ================= network (nmcli backend) =================
    property string netIface: ""
    property string netSsid: ""
    property int netSignal: 0
    property bool wifiEnabled: true
    property var wifiNets: []          // { inUse, signal, security, ssid }
    property bool wifiScanning: false
    property string wifiError: ""
    property string wifiPwSsid: ""     // ssid currently asking for a password

    Process {
        id: netCheck
        command: ["sh", "-c", "ip -o route get 1.1.1.1 2>/dev/null | awk '{print $5; exit}'"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.netIface = text.trim() }
    }
    Process {
        id: ssidCheck
        command: ["sh", "-c", "nmcli -e no -t -f active,ssid,signal dev wifi 2>/dev/null | sed -n 's/^yes://p' | head -1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim();
                const i = line.lastIndexOf(":");
                if (i < 0) { root.netSsid = line; root.netSignal = 0; return; }
                root.netSsid = line.substring(0, i);
                root.netSignal = parseInt(line.substring(i + 1)) || 0;
            }
        }
    }
    Process {
        id: radioCheck
        command: ["sh", "-c", "nmcli -t radio wifi 2>/dev/null"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.wifiEnabled = text.trim() === "enabled" }
    }
    function toggleWifi() {
        Quickshell.execDetached(["sh", "-c",
            "nmcli radio wifi | grep -q enabled && nmcli radio wifi off || nmcli radio wifi on"]);
        netRecheck.start();
    }
    Timer { id: netRecheck; interval: 800; onTriggered: { radioCheck.running = true; netCheck.running = true; ssidCheck.running = true } }

    function scanWifi() {
        root.wifiScanning = true;
        wifiScan.running = true;
    }
    Process {
        id: wifiScan
        command: ["nmcli", "-t", "-e", "no", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "dev", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const nets = [];
                const seen = {};
                for (const line of text.split("\n")) {
                    const p = line.split(":");
                    if (p.length < 4) continue;
                    const ssid = p.slice(3).join(":").trim();
                    if (ssid === "" || seen[ssid]) continue;
                    seen[ssid] = true;
                    nets.push({
                        inUse: p[0].trim() === "*",
                        signal: parseInt(p[1]) || 0,
                        security: p[2].trim(),
                        ssid: ssid
                    });
                }
                nets.sort((a, b) => (b.inUse - a.inUse) || (b.signal - a.signal));
                root.wifiNets = nets;
            }
        }
        onExited: root.wifiScanning = false
    }
    Process {
        id: wifiConn
        property string ssid: ""
        property string pw: ""
        command: pw === "" ? ["nmcli", "dev", "wifi", "connect", ssid]
                           : ["nmcli", "dev", "wifi", "connect", ssid, "password", pw]
        stderr: StdioCollector { onStreamFinished: root.wifiError = text.trim() }
        onExited: exitCode => {
            if (exitCode !== 0) {
                root.wifiPwSsid = wifiConn.ssid;   // likely needs a password
            } else {
                root.wifiPwSsid = "";
                root.wifiError = "";
            }
            netRecheck.start();
            wifiScan.running = true;
        }
    }
    function connectWifi(ssid, pw) {
        root.wifiError = "";
        wifiConn.ssid = ssid;
        wifiConn.pw = pw;
        wifiConn.running = true;
    }

    // ================= clipboard (cliphist backend) =================
    property var clipEntries: []       // { cid, preview }
    Process {
        id: clipList
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab < 1) continue;
                    out.push({ cid: line.substring(0, tab), preview: line.substring(tab + 1) });
                }
                root.clipEntries = out;
            }
        }
    }
    function copyClip(cid) {
        Quickshell.execDetached(["sh", "-c",
            "printf '%s' '" + cid + "' | cliphist decode | wl-copy"]);
    }

    // slow poll for passive state
    Timer {
        interval: 10000; running: true; repeat: true
        onTriggered: { netCheck.running = true; nlCheck.running = true; radioCheck.running = true; ssidCheck.running = true; briGet.running = true; recCheck.running = true; batExtra.running = true }
    }

    // ================= quattro ports: dnd / recording indicator =================
    property bool doNotDisturb: false      // history still records; toasts suppressed

    // screen recording detector (wf-recorder / gpu-screen-recorder / wl-screenrec)
    // NOTE: -x (exact process name) — `pgrep -f` would match this very
    // command's own cmdline and report recording forever.
    property bool recActive: false
    // (kernel comm names are truncated to 15 chars, so match the truncation)
    readonly property var recProcs: ["wf-recorder", "gpu-screen-recorder", "wl-screenrec"]
        .map(p => p.substring(0, 15))
    Process {
        id: recCheck
        command: ["sh", "-c",
            "{ " + root.recProcs.map(p => "pgrep -x " + p + " >/dev/null").join(" || ")
            + "; } && echo on || echo off"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.recActive = text.trim() === "on" }
    }
    function stopRecording() {
        Quickshell.execDetached(["sh", "-c",
            root.recProcs.map(p => "pkill -INT -x " + p).join("; ")]);
        recRecheck.start();
    }
    Timer { id: recRecheck; interval: 600; onTriggered: recCheck.running = true }

    // ================= battery details (quattro-style power panel) =================
    property int batCycles: -1
    property real batHealth: -1
    Process {
        id: batExtra
        command: ["sh", "-c",
            "b=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1); " +
            "[ -n \"$b\" ] || { echo '-1 -1 -1'; exit 0; }; " +
            "c=$(cat $b/cycle_count 2>/dev/null || echo -1); " +
            "f=$(cat $b/energy_full 2>/dev/null || cat $b/charge_full 2>/dev/null || echo -1); " +
            "d=$(cat $b/energy_full_design 2>/dev/null || cat $b/charge_full_design 2>/dev/null || echo -1); " +
            "echo \"$c $f $d\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(/\s+/).map(Number);
                if (p.length < 3) return;
                root.batCycles = p[0];
                root.batHealth = (p[1] > 0 && p[2] > 0) ? 100 * p[1] / p[2] : -1;
            }
        }
    }
    function batStateText(st) {
        if (st === UPowerDeviceState.Charging) return "charging";
        if (st === UPowerDeviceState.Discharging) return "discharging";
        if (st === UPowerDeviceState.FullyCharged) return "full";
        if (st === UPowerDeviceState.PendingCharge) return "pending charge";
        return "idle";
    }
    function fmtSecs(sec) {
        if (!sec || sec <= 0) return "—";
        const h = Math.floor(sec / 3600), m = Math.round((sec % 3600) / 60);
        return h > 0 ? h + "h " + m + "m" : m + "m";
    }

    // ================= media (MPRIS) =================
    readonly property var mprisPlayers: Mpris.players ? Mpris.players.values : []
    readonly property var activePlayer: {
        for (const p of mprisPlayers) if (p.isPlaying) return p;
        return mprisPlayers.length > 0 ? mprisPlayers[0] : null;
    }
    readonly property bool hasMedia: activePlayer !== null
        && ((activePlayer.trackTitle ?? "") !== "" || (activePlayer.trackArtist ?? "") !== "")

    // ================= intuitive level-based icons =================
    function batIcon(pct, charging) {
        if (charging) return "󰂄";
        return pct >= 90 ? "󰁹" : pct >= 70 ? "󰂀" : pct >= 50 ? "󰁾"
             : pct >= 30 ? "󰁼" : pct >= 15 ? "󰁻" : "󰁺";
    }
    function volIcon(vol, muted) {
        if (muted) return "󰖁";
        return vol >= 0.66 ? "󰕾" : vol >= 0.33 ? "󰖀" : "󰕿";
    }
    function wifiIcon(sig) {
        return sig > 75 ? "󰤨" : sig > 50 ? "󰤥" : sig > 25 ? "󰤢" : "󰤟";
    }

    // ================= display persistence =================
    // wlr-randr changes die with the compositor; every apply rewrites
    // ~/.config/mango/monitors.sh, replayed by exec-once at startup.
    property var dispPersist: ({})

    function _writeDispState() {
        let script = "#!/bin/sh\n# generated by quickshell — display settings\nsleep 1\n";
        for (const name in dispPersist) {
            const e = dispPersist[name];
            script += "wlr-randr --output '" + name + "'";
            if (e.on === false) { script += " --off\n"; continue; }
            if (e.on === true)  script += " --on";
            if (e.mode)         script += " --mode " + e.mode;
            if (e.scale !== undefined)     script += " --scale " + e.scale;
            if (e.transform !== undefined) script += " --transform " + e.transform;
            if (e.pos !== undefined)       script += " --pos " + e.pos;
            script += "\n";
        }
        Quickshell.execDetached(["sh", "-c",
            'mkdir -p "$HOME/.config/mango" && printf %s "$1" > "$HOME/.config/mango/monitors.json" && printf %s "$2" > "$HOME/.config/mango/monitors.sh" && chmod +x "$HOME/.config/mango/monitors.sh"',
            "_", JSON.stringify(dispPersist), script]);
    }

    function persistDisplay(outName, patch) {
        const next = Object.assign({}, dispPersist);
        next[outName] = Object.assign({}, next[outName] ?? {}, patch);
        dispPersist = next;
        _writeDispState();
    }

    function applyPersisted() {
        for (const name in dispPersist) {
            const e = dispPersist[name];
            const cmd = ["wlr-randr", "--output", name];
            if (e.on === false) { Quickshell.execDetached(cmd.concat(["--off"])); continue; }
            if (e.on === true)  cmd.push("--on");
            if (e.mode)         cmd.push("--mode", e.mode);
            if (e.scale !== undefined)     cmd.push("--scale", String(e.scale));
            if (e.transform !== undefined) cmd.push("--transform", String(e.transform));
            if (e.pos !== undefined)       cmd.push("--pos", String(e.pos));
            if (cmd.length > 3) Quickshell.execDetached(cmd);
        }
    }

    // load saved state at startup, then self-apply — no exec-once line required
    Process {
        id: dispLoad
        command: ["sh", "-c", 'cat "$HOME/.config/mango/monitors.json" 2>/dev/null || echo "{}"']
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.dispPersist = JSON.parse(text.trim() || "{}"); }
                catch (e) { root.dispPersist = {}; }
                dispApplyDelay.start();
            }
        }
    }
    Timer { id: dispApplyDelay; interval: 1500; onTriggered: root.applyPersisted() }

    SystemClock { id: clock; precision: SystemClock.Minutes }

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
                if (root._cpuPrev) {
                    const dt = total - root._cpuPrev.total;
                    const di = idle - root._cpuPrev.idle;
                    if (dt > 0) root.cpuPct = Math.max(0, Math.min(100, 100 * (1 - di / dt)));
                }
                root._cpuPrev = { total: total, idle: idle };

                // --- ram ---
                const mt = /MemTotal:\s+(\d+)/.exec(sec[1]);
                const ma = /MemAvailable:\s+(\d+)/.exec(sec[1]);
                if (mt && ma) {
                    const total = parseInt(mt[1]), avail = parseInt(ma[1]);
                    root.memPct = 100 * (1 - avail / total);
                    root.memTotalG = total / 1048576;
                    root.memUsedG = (total - avail) / 1048576;
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
                if (root._netPrev && now > root._netStamp) {
                    const dt = (now - root._netStamp) / 1000;
                    root.netRx = Math.max(0, (rx - root._netPrev.rx) / dt);
                    root.netTx = Math.max(0, (tx - root._netPrev.tx) / dt);
                }
                root._netPrev = { rx: rx, tx: tx };
                root._netStamp = now;

                // --- disk / (df -Ph: fs size used avail use% mount) ---
                const df = sec[3].trim().split(/\s+/);
                if (df.length >= 5) {
                    root.diskUsed = df[2];
                    root.diskAvail = df[3];
                    root.diskPct = parseInt(df[4]) || 0;
                }

                // --- gpu ---
                const g = parseInt(sec[4].trim());
                root.gpuPct = isNaN(g) ? -1 : g;

                // --- cpu freq (avg MHz) ---
                if (sec.length > 5) {
                    const f = parseFloat(sec[5].trim());
                    root.cpuMhz = isNaN(f) ? -1 : f;
                }

                // --- gpu vram (amd: bytes, nvidia: MiB) ---
                if (sec.length > 6) {
                    const gp = sec[6].trim().split(/\s+/);
                    if (gp[0] === "amd" && gp.length >= 3) {
                        root.gpuMemUsed = parseInt(gp[1]) / 1073741824;
                        root.gpuMemTotal = parseInt(gp[2]) / 1073741824;
                    } else if (gp[0] === "nv" && gp.length >= 3) {
                        root.gpuMemUsed = parseInt(gp[1]) / 1024;
                        root.gpuMemTotal = parseInt(gp[2]) / 1024;
                    } else {
                        root.gpuMemUsed = -1;
                        root.gpuMemTotal = -1;
                    }
                }
            }
        }
    }
    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: sysPoll.running = true
    }

    // ================= OSD (replaces swayosd) =================
    // Volume OSD fires automatically on any pipewire volume/mute change
    // (hardware keys, wpctl, this shell). Brightness keys should call the
    // IPC below so the OSD shows:   qs ipc call osd brightnessUp
    property string osdKind: "volume"
    property bool osdShown: false
    property bool osdSuppressed: false     // no OSD while quick settings is open
    property bool osdReady: false          // no OSD storm during startup
    Timer { interval: 2000; running: true; onTriggered: root.osdReady = true }
    Timer { id: osdHide; interval: 1600; onTriggered: root.osdShown = false }
    function showOsd(kind) {
        if (!osdReady || osdSuppressed) return;
        osdKind = kind;
        osdShown = true;
        osdHide.restart();
    }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
        function onVolumeChanged() { root.showOsd("volume") }
        function onMutedChanged() { root.showOsd("volume") }
    }

    IpcHandler {
        target: "osd"
        function volumeUp(): void {
            const a = Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null;
            if (a) { a.muted = false; a.volume = Math.min(1.5, a.volume + 0.05); }
        }
        function volumeDown(): void {
            const a = Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null;
            if (a) a.volume = Math.max(0, a.volume - 0.05);
        }
        function mute(): void {
            const a = Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null;
            if (a) a.muted = !a.muted;
        }
        function micMute(): void {
            const a = Pipewire.defaultAudioSource ? Pipewire.defaultAudioSource.audio : null;
            if (a) a.muted = !a.muted;
        }
        function brightnessUp(): void {
            root.setBrightness((root.brightness < 0 ? 50 : root.brightness) + 5);
            root.showOsd("brightness");
        }
        function brightnessDown(): void {
            root.setBrightness((root.brightness < 0 ? 50 : root.brightness) - 5);
            root.showOsd("brightness");
        }
    }

    PanelWindow {
        visible: root.osdShown
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        anchors { bottom: true }
        margins { bottom: 140 }
        implicitWidth: 340
        implicitHeight: 74
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: root.bg0h
            border.width: 1
            border.color: root.bg2

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                spacing: 14

                readonly property var sink: Pipewire.defaultAudioSink
                readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
                readonly property real frac: root.osdKind === "volume"
                    ? (sink && sink.audio ? Math.min(1, sink.audio.volume) : 0)
                    : Math.max(0, root.brightness) / 100

                Text {
                    text: root.osdKind === "brightness" ? "󰃞"
                        : parent.muted ? "󰖁" : "󰕾"
                    color: (root.osdKind === "volume" && parent.muted) ? root.gray : root.yellow
                    font { family: root.fontFamily; bold: true; pixelSize: root.iconSize + 2 }
                }
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 8
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width; height: 8; radius: 4
                        color: root.bg2
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.parent.frac * parent.width
                        height: 8; radius: 4
                        color: (root.osdKind === "volume" && parent.parent.muted) ? root.gray : root.yellow
                    }
                }
                Text {
                    text: (root.osdKind === "volume" && parent.muted) ? "mute"
                        : Math.round(parent.frac * 100) + "%"
                    color: root.fg
                    font { family: root.fontFamily; bold: true; pixelSize: root.fontSize }
                    Layout.preferredWidth: 62
                }
            }
        }
    }

    // ================= notifications: daemon + history =================
    ListModel { id: notifHistory }

    NotificationServer {
        id: notifServer
        onNotification: n => {
            n.tracked = true;
            notifHistory.insert(0, {
                nApp: n.appName || "notification",
                nSummary: n.summary || "",
                nBody: n.body || "",
                nTime: Qt.formatTime(new Date(), "HH:mm")
            });
            if (notifHistory.count > 50) notifHistory.remove(50, notifHistory.count - 50);
        }
    }

    PanelWindow {
        anchors { top: true; right: true }
        margins { top: root.barHeight + 8; right: 8 }
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: 360
        implicitHeight: Math.max(1, toastCol.implicitHeight)
        visible: notifServer.trackedNotifications.values.length > 0 && !root.doNotDisturb
        color: "transparent"

        ColumnLayout {
            id: toastCol
            width: parent.width
            spacing: 8
            Repeater {
                model: notifServer.trackedNotifications
                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: tInner.implicitHeight + 20
                    radius: 8
                    color: root.bg1
                    border.width: 1
                    border.color: modelData.urgency === NotificationUrgency.Critical ? root.red : root.bg2
                    ColumnLayout {
                        id: tInner
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                        spacing: 2
                        Text {
                            Layout.fillWidth: true
                            text: modelData.appName + (modelData.summary ? "  ·  " + modelData.summary : "")
                            color: root.yellow; elide: Text.ElideRight
                            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize }
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: modelData.body !== ""
                            text: modelData.body
                            color: root.fg; wrapMode: Text.Wrap
                            maximumLineCount: 4; elide: Text.ElideRight
                            textFormat: Text.PlainText
                            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 1 }
                        }
                    }
                    MouseArea { anchors.fill: parent; onClicked: modelData.dismiss() }
                    Timer {
                        interval: modelData.urgency === NotificationUrgency.Critical ? 30000 : 6000
                        running: true
                        onTriggered: modelData.expire()
                    }
                }
            }
        }
    }

    // ======================================================================
    //                        BAR (one per monitor)
    // ======================================================================
    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen
            property var modelData

            PanelWindow {
            id: bar
            screen: perScreen.modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: root.barHeight
            color: root.bg0

            // ---- per-monitor mango state via `mmsg watch monitor <name>` ----
            property var mTags: []
            property string mLayoutSym: "?"
            property string mKbLayout: ""
            property string mTitle: ""

            Process {
                id: monWatch
                running: true
                command: ["mmsg", "watch", "monitor", perScreen.modelData.name]
                stdout: SplitParser {
                    onRead: data => {
                        try {
                            const j = JSON.parse(data);
                            bar.mTags = j.tags ?? [];
                            bar.mLayoutSym = j.layout_symbol ?? "?";
                            bar.mKbLayout = j.keyboardlayout ?? "";
                            bar.mTitle = (j.active_client && j.active_client.title) ? j.active_client.title : "";
                        } catch (e) { /* partial line, ignore */ }
                    }
                }
                onExited: monRestart.start()
            }
            Timer { id: monRestart; interval: 2000; onTriggered: monWatch.running = true }

            // ---- output state via wlr-output-management (wlr-randr) ----
            property string dispTarget: perScreen.modelData.name
            property var outModes: []
            property real outScale: 1
            property bool outEnabled: true
            property string outTransform: "normal"
            property var outAll: []          // every output: name, x, y, logical w/h, enabled
            Process {
                id: dispInfo
                command: ["wlr-randr", "--json"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            const outs = JSON.parse(text);
                            const all = [];
                            for (const o of outs) {
                                const cm = (o.modes ?? []).find(m => m.current)
                                        ?? (o.modes ?? []).find(m => m.preferred)
                                        ?? (o.modes ?? [])[0] ?? { width: 0, height: 0 };
                                const sc = o.scale ?? 1;
                                const rot = String(o.transform ?? "normal");
                                const swap = rot === "90" || rot === "270"
                                          || rot === "flipped-90" || rot === "flipped-270";
                                all.push({
                                    name: o.name,
                                    x: o.position ? o.position.x : 0,
                                    y: o.position ? o.position.y : 0,
                                    w: Math.round((swap ? cm.height : cm.width) / sc),
                                    h: Math.round((swap ? cm.width : cm.height) / sc),
                                    enabled: o.enabled !== false
                                });
                            }
                            bar.outAll = all;

                            const me = outs.find(o => o.name === bar.dispTarget);
                            if (!me) return;
                            bar.outScale = me.scale ?? 1;
                            bar.outEnabled = me.enabled !== false;
                            bar.outTransform = String(me.transform ?? "normal");
                            const seen = {};
                            const modes = [];
                            for (const m of (me.modes ?? [])) {
                                const key = m.width + "x" + m.height + "@" + Math.round(m.refresh);
                                if (seen[key]) { if (m.current) seen[key].current = true; continue; }
                                const e = { w: m.width, h: m.height, refresh: m.refresh,
                                            current: m.current === true };
                                seen[key] = e;
                                modes.push(e);
                            }
                            modes.sort((a, b) => (b.w * b.h - a.w * a.h) || (b.refresh - a.refresh));
                            bar.outModes = modes;
                        } catch (e) { bar.outModes = []; }
                    }
                }
            }
            Timer { id: dispRefresh; interval: 800; onTriggered: dispInfo.running = true }
            function applyMode(m) {
                Quickshell.execDetached(["wlr-randr", "--output", bar.dispTarget,
                    "--mode", m.w + "x" + m.h + "@" + m.refresh.toFixed(3)]);
                root.persistDisplay(bar.dispTarget, { mode: m.w + "x" + m.h + "@" + m.refresh.toFixed(3) });
                dispRefresh.restart();
            }
            function applyScale(v) {
                Quickshell.execDetached(["wlr-randr", "--output", bar.dispTarget, "--scale", String(v)]);
                root.persistDisplay(bar.dispTarget, { scale: v });
                dispRefresh.restart();
            }
            function applyTransform(t) {
                Quickshell.execDetached(["wlr-randr", "--output", bar.dispTarget, "--transform", t]);
                root.persistDisplay(bar.dispTarget, { transform: t });
                dispRefresh.restart();
            }
            function applyEnabled(on) {
                Quickshell.execDetached(["wlr-randr", "--output", bar.dispTarget, on ? "--on" : "--off"]);
                root.persistDisplay(bar.dispTarget, { on: on });
                dispRefresh.restart();
            }
            function placeRelative(dir, refName) {
                const t = bar.outAll.find(o => o.name === bar.dispTarget);
                const r = bar.outAll.find(o => o.name === refName);
                if (!t || !r) return;
                let x = r.x, y = r.y;
                if (dir === "left")  { x = r.x - t.w; y = r.y; }
                if (dir === "right") { x = r.x + r.w; y = r.y; }
                if (dir === "above") { x = r.x; y = r.y - t.h; }
                if (dir === "below") { x = r.x; y = r.y + r.h; }
                if (dir === "mirror"){ x = r.x; y = r.y; }
                Quickshell.execDetached(["wlr-randr", "--output", bar.dispTarget, "--pos", x + "," + y]);
                root.persistDisplay(bar.dispTarget, { pos: x + "," + y });
                dispRefresh.restart();
            }

            // popup management: one at a time, closable from the overlay
            readonly property var allPopups: [
                launcherPopup, layoutPopup, wifiPopup, btPopup, audioPopup,
                displayPopup, batteryPopup, sysPopup, notifPopup, clipPopup,
                calPopup, powerPopup, trayMenuPopup]
            readonly property bool anyPopupOpen:
                launcherPopup.visible || layoutPopup.visible || wifiPopup.visible
                || btPopup.visible || audioPopup.visible || displayPopup.visible
                || batteryPopup.visible || sysPopup.visible || notifPopup.visible
                || clipPopup.visible || calPopup.visible || powerPopup.visible
                || trayMenuPopup.visible
            onAnyPopupOpenChanged: root.osdSuppressed = anyPopupOpen
            function closeAllPopups() {
                for (const o of allPopups) o.visible = false;
            }
            function togglePopupAt(p, item) {
                const x = item.mapToItem(null, 0, 0).x;
                p.margins.left = Math.max(8, Math.min(x, bar.width - p.implicitWidth - 8));
                togglePopup(p);
            }
            property var trayMenuHandle: null
            function openTrayMenu(item, x) {
                closeAllPopups();
                trayMenuHandle = item.menu;
                trayMenuPopup.anchor.rect.x = Math.min(x, bar.width - trayMenuPopup.implicitWidth - 8);
                trayMenuPopup.visible = true;
            }
            function togglePopup(p) {
                const wasOpen = p.visible;
                closeAllPopups();
                p.visible = !wasOpen;
            }

            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 2; color: root.bg1 }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                // ===== launcher =====
                BarButton {
                    text: "󰣇"
                    px: root.iconSize
                    fgColor: root.blue
                    onClicked: { bar.togglePopup(launcherPopup);
                                 if (launcherPopup.visible) launchSearch.forceActiveFocus() }
                }

                // ===== overview (mango hycov) =====
                BarButton {
                    text: "󰕰"
                    px: root.iconSize
                    fgColor: root.aqua
                    tooltip: "overview"
                    onClicked: root.dispatch("toggleoverview")
                }

                // ===== tags =====
                RowLayout {
                    spacing: 3
                    Repeater {
                        model: bar.mTags
                        Rectangle {
                            required property var modelData
                            readonly property bool on: modelData.is_active === true
                            readonly property bool occupied: (modelData.client_count ?? 0) > 0
                            width: 34; height: 28; radius: 5
                            color: on ? root.yellow : (tagMa.containsMouse ? root.bg2 : root.bg1)
                            border.width: modelData.is_urgent === true ? 1 : 0
                            border.color: root.red
                            opacity: (on || occupied) ? 1.0 : 0.45
                            Text {
                                anchors.centerIn: parent
                                text: modelData.index
                                color: parent.on ? root.bg0 : root.fg
                                font { family: root.fontFamily; bold: true; pixelSize: root.fontSize }
                            }
                            Rectangle {
                                visible: parent.occupied && !parent.on
                                width: 5; height: 5; radius: 2.5
                                color: root.orange
                                anchors { top: parent.top; right: parent.right; margins: 2 }
                            }
                            MouseArea {
                                id: tagMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.dispatch("view," + modelData.index)
                            }
                        }
                    }
                }

                // ===== layout / tiling mode =====
                BarButton {
                    text: bar.mLayoutSym
                    fgColor: root.green
                    tooltip: "layout (click: picker, right: cycle, middle: toggle float)"
                    onClicked: bar.togglePopup(layoutPopup)
                    onRightClicked: root.dispatch("switch_layout")
                    onMiddleClicked: root.dispatch("togglefloating")
                }

                // ===== taskbar (icon-only) =====
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    orientation: ListView.Horizontal
                    clip: true
                    spacing: 6
                    model: ToplevelManager.toplevels
                    delegate: Rectangle {
                        id: task
                        required property var modelData
                        readonly property var dEntry: {
                            try { return DesktopEntries.heuristicLookup(modelData.appId); }
                            catch (e) { return null; }
                        }
                        readonly property string iconSrc:
                            (dEntry && dEntry.icon) ? Quickshell.iconPath(dEntry.icon, true) : ""
                        width: root.barHeight - 6
                        height: root.barHeight - 8
                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        radius: 6
                        color: modelData.activated ? root.bg2 : (taskMa.containsMouse ? root.bg1 : "transparent")
                        IconImage {
                            anchors.centerIn: parent
                            width: root.iconSize + 2
                            height: root.iconSize + 2
                            source: task.iconSrc
                            visible: task.iconSrc !== ""
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: task.iconSrc === ""
                            text: (modelData.appId || modelData.title || "?").charAt(0).toUpperCase()
                            color: modelData.activated ? root.yellow : root.fg
                            font { family: root.fontFamily; bold: true; pixelSize: root.iconSize - 4 }
                        }
                        Rectangle {
                            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                            width: parent.width - 12
                            height: 3
                            radius: 1.5
                            color: root.yellow
                            visible: modelData.activated
                        }
                        MouseArea {
                            id: taskMa
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                            onClicked: ev => {
                                if (ev.button === Qt.MiddleButton) modelData.close();
                                else modelData.activate();
                            }
                        }
                        ToolTip.visible: taskMa.containsMouse
                        ToolTip.text: modelData.title || modelData.appId || ""
                        ToolTip.delay: 700
                    }
                }

                // ===== media player (MPRIS) =====
                Rectangle {
                    visible: root.hasMedia
                    implicitWidth: mediaRow.implicitWidth + 16
                    implicitHeight: 30
                    radius: 4
                    color: "transparent"
                    RowLayout {
                        id: mediaRow
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: "󰒮"
                            color: root.activePlayer && root.activePlayer.canGoPrevious ? root.fg : root.bg3
                            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize + 2 }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: if (root.activePlayer && root.activePlayer.canGoPrevious)
                                               root.activePlayer.previous()
                            }
                        }
                        Text {
                            text: root.activePlayer && root.activePlayer.isPlaying ? "󰏤" : "󰐊"
                            color: root.green
                            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize + 4 }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: if (root.activePlayer && root.activePlayer.canTogglePlaying)
                                               root.activePlayer.togglePlaying()
                            }
                        }
                        Text {
                            text: "󰒭"
                            color: root.activePlayer && root.activePlayer.canGoNext ? root.fg : root.bg3
                            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize + 2 }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: if (root.activePlayer && root.activePlayer.canGoNext)
                                               root.activePlayer.next()
                            }
                        }
                        Text {
                            text: {
                                const t = root.activePlayer ? (root.activePlayer.trackTitle ?? "") : "";
                                const a = root.activePlayer ? (root.activePlayer.trackArtist ?? "") : "";
                                return a !== "" ? t + " — " + a : t;
                            }
                            color: root.activePlayer && root.activePlayer.isPlaying ? root.fg : root.fgDim
                            elide: Text.ElideRight
                            Layout.maximumWidth: 240
                            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 1 }
                        }
                    }
                }

                // ===== system tray =====
                RowLayout {
                    spacing: 6
                    Repeater {
                        model: SystemTray.items
                        Item {
                            id: trayItem
                            required property var modelData
                            width: 30; height: 30
                            IconImage {
                                anchors.fill: parent
                                source: trayItem.modelData.icon
                                smooth: true
                                asynchronous: true
                            }
                            function openMenu() {
                                const p = trayItem.mapToItem(null, 0, 0);
                                bar.openTrayMenu(trayItem.modelData, p.x);
                            }
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                onClicked: ev => {
                                    const item = trayItem.modelData;
                                    if (ev.button === Qt.RightButton) {
                                        if (item.hasMenu) trayItem.openMenu();
                                        else item.secondaryActivate();
                                    } else if (ev.button === Qt.MiddleButton) {
                                        item.secondaryActivate();
                                    } else {
                                        if (item.onlyMenu && item.hasMenu) trayItem.openMenu();
                                        else item.activate();
                                    }
                                }
                            }
                            ToolTip.visible: false
                        }
                    }
                }

                // ===== screen recording indicator (visible only while recording) =====
                BarButton {
                    visible: root.recActive
                    text: "󰻂"
                    px: root.iconSize
                    fgColor: root.red
                    tooltip: "recording — click to stop"
                    onClicked: root.stopRecording()
                }

                // ===== system monitor chip =====
                Rectangle {
                    id: sysChip
                    implicitWidth: chipRow.implicitWidth + 20
                    implicitHeight: 30
                    radius: 4
                    color: chipMa.containsMouse ? root.bg1 : "transparent"

                    RowLayout {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 12

                        ChipStat {
                            icon: "󰻠"
                            value: Math.round(root.cpuPct) + "%"
                                   + (root.cpuMhz > 0 ? " " + (root.cpuMhz / 1000).toFixed(1) + "GHz" : "")
                        }
                        ChipStat { icon: "󰍛"; value: root.memUsedG.toFixed(1) + "/" + root.memTotalG.toFixed(0) + "G" }
                        ChipStat { icon: "󰋊"; value: root.diskUsed + "/" + root.diskAvail }
                        ChipStat { icon: "󰇚"; value: root.fmtRateShort(root.netRx) }
                        ChipStat { icon: "󰕒"; value: root.fmtRateShort(root.netTx) }
                    }
                    MouseArea {
                        id: chipMa
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: ev => {
                            if (ev.button === Qt.RightButton) bar.togglePopupAt(sysPopup, sysChip);
                            else Quickshell.execDetached(["kitty", "--class", "btop", "-e", "btop"]);
                        }
                    }
                    ToolTip.visible: chipMa.containsMouse
                    ToolTip.text: "click: btop · right-click: system info"
                    ToolTip.delay: 700
                }

                // ===== wifi =====
                StatusPill {
                    id: wifiPill
                    icon: root.netIface === "" ? "󰖪"
                        : (root.netIface.startsWith("w") ? root.wifiIcon(root.netSignal) : "󰈀")
                    iconColor: root.netIface === "" ? root.red : root.green
                    value: root.netIface === "" ? "off"
                         : (root.netIface.startsWith("w")
                            ? (root.netSsid !== "" ? root.netSsid : root.netIface)
                            : root.netIface)
                    maxValueWidth: 150
                    tooltip: "network"
                    onClicked: {
                        bar.togglePopupAt(wifiPopup, wifiPill);
                        if (wifiPopup.visible && root.wifiEnabled) root.scanWifi();
                    }
                }

                // ===== bluetooth =====
                StatusPill {
                    id: btPill
                    readonly property var adapter: Bluetooth.defaultAdapter
                    readonly property var connectedDev: {
                        if (!adapter || !adapter.enabled) return null;
                        for (const d of adapter.devices.values) if (d.connected) return d;
                        return null;
                    }
                    visible: adapter !== null
                    icon: !adapter || !adapter.enabled ? "󰂲" : (connectedDev ? "󰂱" : "󰂯")
                    iconColor: !adapter || !adapter.enabled ? root.gray
                             : (connectedDev ? root.blue : root.fg0)
                    value: !adapter || !adapter.enabled ? "off"
                         : (connectedDev ? connectedDev.name : "on")
                    maxValueWidth: 130
                    tooltip: "bluetooth"
                    onClicked: bar.togglePopupAt(btPopup, btPill)
                }

                // ===== audio =====
                StatusPill {
                    id: audioPill
                    readonly property var sink: Pipewire.defaultAudioSink
                    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
                    icon: sink && sink.audio ? root.volIcon(sink.audio.volume, sink.audio.muted) : "󰕿"
                    iconColor: sink && sink.audio && sink.audio.muted ? root.gray : root.fg0
                    value: sink && sink.audio
                           ? (sink.audio.muted ? "mute" : Math.round(sink.audio.volume * 100) + "%")
                           : "--"
                    tooltip: "audio — scroll: volume, right-click: mute"
                    onClicked: bar.togglePopupAt(audioPopup, audioPill)
                    onRightClicked: if (sink && sink.audio) sink.audio.muted = !sink.audio.muted
                    onWheelMoved: d => {
                        if (sink && sink.audio)
                            sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + (d > 0 ? 0.05 : -0.05)));
                    }
                }

                // ===== display (brightness + night light) =====
                StatusPill {
                    id: displayPill
                    icon: "󰍹"
                    iconColor: root.nightLight ? root.orange : root.fg0
                    value: root.brightness >= 0 ? root.brightness + "%" : ""
                    tooltip: "display — brightness & night light"
                    onClicked: bar.togglePopupAt(displayPopup, displayPill)
                    onWheelMoved: d => root.adjustFromWheel(d)
                }

                // ===== battery =====
                StatusPill {
                    id: batteryPill
                    readonly property var bat: UPower.displayDevice
                    readonly property bool charging: bat && bat.state === UPowerDeviceState.Charging
                    visible: bat !== null && bat.isLaptopBattery
                    icon: bat ? root.batIcon(bat.percentage * 100, charging) : "󰁹"
                    iconColor: charging ? root.aqua
                             : (bat && bat.percentage < 0.2 ? root.red : root.green)
                    value: bat ? Math.round(bat.percentage * 100) + "%" : ""
                    tooltip: "battery & power profile"
                    onClicked: bar.togglePopupAt(batteryPopup, batteryPill)
                }

                // ===== notification center =====
                BarButton {
                    px: root.iconSize - 4
                    text: root.doNotDisturb ? "󰂛"
                        : (notifHistory.count > 0 ? "󰂚 " + notifHistory.count : "󰂜")
                    fgColor: root.doNotDisturb ? root.red
                           : (notifHistory.count > 0 ? root.yellow : root.fgDim)
                    tooltip: root.doNotDisturb ? "do not disturb (right-click to allow)" : "notifications (right-click: DND)"
                    onClicked: bar.togglePopup(notifPopup)
                    onRightClicked: root.doNotDisturb = !root.doNotDisturb
                }

                // ===== clipboard =====
                BarButton {
                    text: "󰅍"
                    px: root.iconSize
                    fgColor: root.fg0
                    onClicked: { bar.togglePopup(clipPopup);
                                 if (clipPopup.visible) clipList.running = true }
                }

                // ===== clock =====
                BarButton {
                    text: Qt.formatDateTime(clock.date, "ddd dd MMM  HH:mm")
                    fgColor: root.fg
                    onClicked: bar.togglePopup(calPopup)
                }

                // ===== power =====
                BarButton {
                    text: "⏻"
                    px: root.iconSize
                    fgColor: root.red
                    onClicked: bar.togglePopup(powerPopup)
                }
            }

            // ================================================================
            //                        POPUPS
            // ================================================================

            // ---------- app launcher ----------
            PanelWindow {
                id: launcherPopup
                screen: perScreen.modelData
                anchors { top: true; left: true }
                margins { top: root.barHeight + 4; left: 8 }
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
                implicitWidth: 460
                implicitHeight: 560
                visible: false
                color: root.bg0h

                onVisibleChanged: if (!visible) launchSearch.text = ""

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 40
                        radius: 6
                        color: root.bg1
                        border.width: 1
                        border.color: launchSearch.activeFocus ? root.yellow : root.bg2
                        TextInput {
                            id: launchSearch
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            verticalAlignment: TextInput.AlignVCenter
                            color: root.fg
                            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize }
                            clip: true
                            onAccepted: {
                                if (launchList.count > 0) {
                                    const item = launchList.itemAtIndex(0);
                                    if (item) item.launch();
                                }
                            }
                            Keys.onEscapePressed: launcherPopup.visible = false
                            Text {
                                visible: launchSearch.text === ""
                                text: "search apps…"
                                color: root.gray
                                anchors.verticalCenter: parent.verticalCenter
                                font { family: root.fontFamily; bold: true; pixelSize: root.fontSize }
                            }
                        }
                    }

                    ListView {
                        id: launchList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        ScrollBar.vertical: GruvScrollBar {}
                        spacing: 2
                        model: ScriptModel {
                            values: {
                                const q = launchSearch.text.toLowerCase();
                                return [...DesktopEntries.applications.values]
                                    .filter(e => !e.noDisplay &&
                                        (q === "" || e.name.toLowerCase().includes(q)))
                                    .sort((a, b) => a.name.localeCompare(b.name));
                            }
                        }
                        delegate: Rectangle {
                            required property var modelData
                            function launch() { modelData.execute(); launcherPopup.visible = false }
                            width: launchList.width
                            height: 44
                            radius: 6
                            color: appMa.containsMouse ? root.bg1 : "transparent"
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8
                                IconImage {
                                    width: 28; height: 28
                                    source: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    color: root.fg
                                    elide: Text.ElideRight
                                    font { family: root.fontFamily; bold: true; pixelSize: root.fontSize }
                                }
                            }
                            MouseArea {
                                id: appMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: parent.launch()
                            }
                        }
                    }
                }
            }

            // ---------- layout picker ----------
            PopupWindow {
                id: layoutPopup
                anchor.window: bar
                anchor.rect.x: 90
                anchor.rect.y: root.barHeight
                implicitWidth: 270
                implicitHeight: layoutCol.implicitHeight + 16
                visible: false
                color: root.bg0h

                ColumnLayout {
                    id: layoutCol
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 2
                    Repeater {
                        model: root.mangoLayouts
                        Rectangle {
                            required property var modelData
                            readonly property bool current: bar.mLayoutSym === modelData.sym
                            Layout.fillWidth: true
                            implicitHeight: 36
                            radius: 5
                            color: current ? root.bg2 : (loMa.containsMouse ? root.bg1 : "transparent")
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                Text {
                                    text: modelData.sym
                                    color: parent.parent.current ? root.yellow : root.green
                                    font { family: root.fontFamily; bold: true; pixelSize: root.fontSize }
                                    Layout.preferredWidth: 46
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    color: root.fg
                                    font { family: root.fontFamily; bold: true; pixelSize: root.fontSize }
                                }
                            }
                            MouseArea {
                                id: loMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    root.dispatch("setlayout," + modelData.name);
                                    layoutPopup.visible = false;
                                }
                            }
                        }
                    }
                }
            }

            // ---------- wifi popup ----------
            PanelWindow {
                id: wifiPopup
                screen: perScreen.modelData
                anchors { top: true; left: true }
                margins { top: root.barHeight + 4; left: 8 }
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
                implicitWidth: 370
                implicitHeight: 440
                visible: false
                color: root.bg0h

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Wi-Fi"
                            color: root.yellow
                            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize }
                        }
                        TogglePill {
                            on: root.wifiEnabled
                            onClicked: root.toggleWifi()
                        }
                        ActionChip {
                            label: root.wifiScanning ? "scanning…" : "󰑐 rescan"
                            enabled: root.wifiEnabled && !root.wifiScanning
                            onClicked: root.scanWifi()
                        }
                    }

                    Text {
                        visible: root.wifiError !== ""
                        Layout.fillWidth: true
                        text: root.wifiError
                        color: root.red
                        wrapMode: Text.Wrap
                        font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 2 }
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: wifiCol.implicitHeight
                        clip: true
                        ScrollBar.vertical: GruvScrollBar {}
                        ColumnLayout {
                            id: wifiCol
                            width: parent.width
                            spacing: 4
                            Repeater {
                                model: root.wifiEnabled ? root.wifiNets : []
                                ColumnLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 38
                                        radius: 5
                                        color: modelData.inUse ? root.bg2 : (wnMa.containsMouse ? root.bg1 : "transparent")
                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 6
                                            Text {
                                                text: root.wifiIcon(modelData.signal)
                                                color: modelData.inUse ? root.green : root.fg
                                                font { family: root.fontFamily; bold: true; pixelSize: root.fontSize + 5 }
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.ssid + (modelData.inUse ? "   (connected)" : "")
                                                color: modelData.inUse ? root.green : root.fg
                                                elide: Text.ElideRight
                                                font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 1 }
                                            }
                                            Text {
                                                visible: modelData.security !== ""
                                                text: "󰌾"
                                                color: root.gray
                                                font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 2 }
                                            }
                                        }
                                        MouseArea {
                                            id: wnMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                if (modelData.inUse) return;
                                                root.wifiPwSsid = "";
                                                root.connectWifi(modelData.ssid, "");
                                            }
                                        }
                                    }
                                    RowLayout {
                                        visible: root.wifiPwSsid === modelData.ssid
                                        Layout.fillWidth: true
                                        spacing: 6
                                        Rectangle {
                                            Layout.fillWidth: true
                                            implicitHeight: 32
                                            radius: 5
                                            color: root.bg1
                                            border.width: 1
                                            border.color: root.yellow
                                            TextInput {
                                                id: pwInput
                                                anchors.fill: parent
                                                anchors.leftMargin: 8
                                                anchors.rightMargin: 8
                                                verticalAlignment: TextInput.AlignVCenter
                                                echoMode: TextInput.Password
                                                color: root.fg
                                                clip: true
                                                font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 1 }
                                                onAccepted: root.connectWifi(modelData.ssid, text)
                                            }
                                        }
                                        ActionChip {
                                            label: "join"
                                            accent: true
                                            onClicked: root.connectWifi(modelData.ssid, pwInput.text)
                                        }
                                    }
                                }
                            }
                            Text {
                                visible: !root.wifiEnabled
                                text: "wifi is off"
                                color: root.gray
                                font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 1 }
                            }
                        }
                    }
                }
            }

            // ---------- bluetooth popup ----------
            PanelWindow {
                id: btPopup
                screen: perScreen.modelData
                anchors { top: true; left: true }
                margins { top: root.barHeight + 4; left: 8 }
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                implicitWidth: 340
                implicitHeight: Math.min(460, btHead.implicitHeight + btFlick.contentHeight + 44)
                visible: false
                color: root.bg0h

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        id: btHead
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Bluetooth"
                            color: root.yellow
                            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize }
                        }
                        TogglePill {
                            on: Bluetooth.defaultAdapter !== null && Bluetooth.defaultAdapter.enabled
                            onClicked: {
                                const a = Bluetooth.defaultAdapter;
                                if (a) a.enabled = !a.enabled;
                            }
                        }
                        ActionChip {
                            readonly property var a: Bluetooth.defaultAdapter
                            label: a && a.discovering ? "scanning…" : "󰑐 scan"
                            enabled: a !== null && a.enabled
                            onClicked: { try { a.discovering = !a.discovering; } catch (e) {} }
                        }
                    }

                    Flickable {
                        id: btFlick
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: btCol.implicitHeight
                        clip: true
                        ScrollBar.vertical: GruvScrollBar {}
                        ColumnLayout {
                            id: btCol
                            width: parent.width
                            spacing: 4
                            Repeater {
                                model: ScriptModel {
                                    values: {
                                        const a = Bluetooth.defaultAdapter;
                                        if (!a || !a.enabled) return [];
                                        return [...a.devices.values]
                                            .filter(d => d.paired || d.connected || (d.name ?? "") !== "")
                                            .sort((x, y) => (y.connected - x.connected) || (y.paired - x.paired));
                                    }
                                }
                                Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 40
                                    radius: 5
                                    color: bdMa.containsMouse ? root.bg1 : "transparent"
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 8
                                        Text {
                                            text: modelData.connected ? "󰂱" : "󰂯"
                                            color: modelData.connected ? root.blue : root.fgDim
                                            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize + 4 }
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 0
                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.name || modelData.address || "?"
                                                color: modelData.connected ? root.blue : root.fg
                                                elide: Text.ElideRight
                                                font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 1 }
                                            }
                                            Text {
                                                text: modelData.connected ? "connected — click to disconnect"
                                                    : (modelData.paired ? "paired — click to connect" : "click to connect")
                                                color: root.gray
                                                font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 4 }
                                            }
                                        }
                                        Text {
                                            visible: (modelData.batteryAvailable ?? false)
                                            text: Math.round((modelData.battery ?? 0) * 100) + "%"
                                            color: root.fgDim
                                            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 2 }
                                        }
                                    }
                                    MouseArea {
                                        id: bdMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            if (modelData.connected) modelData.disconnect();
                                            else modelData.connect();
                                        }
                                    }
                                }
                            }
                            Text {
                                visible: Bluetooth.defaultAdapter === null || !Bluetooth.defaultAdapter.enabled
                                text: "bluetooth is off"
                                color: root.gray
                                font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 1 }
                            }
                        }
                    }
                }
            }

            // ---------- audio popup ----------
            PanelWindow {
                id: audioPopup
                screen: perScreen.modelData
                anchors { top: true; left: true }
                margins { top: root.barHeight + 4; left: 8 }
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                implicitWidth: 340
                implicitHeight: audioCol.implicitHeight + 28
                visible: false
                color: root.bg0h

                ColumnLayout {
                    id: audioCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                    spacing: 10

                    SectionLabel { text: "OUTPUT" }
                    RowLayout {
                        spacing: 8
                        readonly property var sink: Pipewire.defaultAudioSink
                        PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
                        Text {
                            text: parent.sink && parent.sink.audio
                                  ? root.volIcon(parent.sink.audio.volume, parent.sink.audio.muted) : "󰕿"
                            color: parent.sink && parent.sink.audio && parent.sink.audio.muted ? root.gray : root.fg0
                            font { family: root.fontFamily; bold: true; pixelSize: root.iconSize }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    const a = Pipewire.defaultAudioSink;
                                    if (a && a.audio) a.audio.muted = !a.audio.muted;
                                }
                            }
                        }
                        GruvSlider {
                            Layout.fillWidth: true
                            value: (parent.sink && parent.sink.audio) ? parent.sink.audio.volume : 0
                            onMoved: v => {
                                const a = Pipewire.defaultAudioSink;
                                if (a && a.audio) a.audio.volume = v;
                            }
                        }
                        Text {
                            text: (parent.sink && parent.sink.audio)
                                  ? Math.round(parent.sink.audio.volume * 100) + "%" : "--"
                            color: root.fgDim
                            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 1 }
                            Layout.preferredWidth: 52
                        }
                    }

                    // output device picker
                    Repeater {
                        model: ScriptModel {
                            values: (Pipewire.nodes ? [...Pipewire.nodes.values] : [])
                                .filter(n => n && n.isSink && !n.isStream && (n.description ?? n.name ?? "") !== "")
                        }
                        Rectangle {
                            required property var modelData
                            readonly property bool current: modelData === Pipewire.defaultAudioSink
                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: 5
                            color: current ? root.bg2 : (devMa.containsMouse ? root.bg1 : "transparent")
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 6
                                Text {
                                    text: parent.parent.current ? "󰄬" : "󰓃"
                                    color: parent.parent.current ? root.green : root.fgDim
                                    font { family: root.fontFamily; bold: true; pixelSize: root.fontSize }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.description ?? modelData.name
                                    color: parent.parent.current ? root.fg0 : root.fg
                                    elide: Text.ElideRight
                                    font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 2 }
                                }
                            }
                            MouseArea {
                                id: devMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: Quickshell.execDetached(["wpctl", "set-default", String(modelData.id)])
                            }
                        }
                    }

                    SectionLabel { text: "INPUT" }
                    RowLayout {
                        spacing: 8
                        readonly property var src: Pipewire.defaultAudioSource
                        PwObjectTracker { objects: [Pipewire.defaultAudioSource] }
                        visible: src !== null
                        Text {
                            text: parent.src && parent.src.audio && parent.src.audio.muted ? "󰍭" : "󰍬"
                            color: parent.src && parent.src.audio && parent.src.audio.muted ? root.gray : root.fg0
                            font { family: root.fontFamily; bold: true; pixelSize: root.iconSize }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    const a = Pipewire.defaultAudioSource;
                                    if (a && a.audio) a.audio.muted = !a.audio.muted;
                                }
                            }
                        }
                        GruvSlider {
                            Layout.fillWidth: true
                            value: (parent.src && parent.src.audio) ? parent.src.audio.volume : 0
                            onMoved: v => {
                                const a = Pipewire.defaultAudioSource;
                                if (a && a.audio) a.audio.volume = v;
                            }
                        }
                        Text {
                            text: (parent.src && parent.src.audio)
                                  ? Math.round(parent.src.audio.volume * 100) + "%" : "--"
                            color: root.fgDim
                            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 1 }
                            Layout.preferredWidth: 52
                        }
                    }
                }
            }

            // ---------- display popup (brightness + night light) ----------
            PanelWindow {
                id: displayPopup
                screen: perScreen.modelData
                property bool resOpen: false
                property string posRef: {
                    const other = bar.outAll.find(o => o.name !== bar.dispTarget);
                    return other ? other.name : "";
                }
                onVisibleChanged: if (visible) {
                    bar.dispTarget = perScreen.modelData.name;
                    resOpen = false;
                    dispInfo.running = true;
                }
                anchors { top: true; left: true }
                margins { top: root.barHeight + 4; left: 8 }
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                implicitWidth: 300
                implicitHeight: dispCol.implicitHeight + 28
                visible: false
                color: root.bg0h

                ColumnLayout {
                    id: dispCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                    spacing: 10

                    SectionLabel { text: "BRIGHTNESS" }
                    RowLayout {
                        spacing: 8
                        visible: root.brightness >= 0
                        Text {
                            text: "󰃞"
                            color: root.fg0
                            font { family: root.fontFamily; bold: true; pixelSize: root.iconSize }
                        }
                        GruvSlider {
                            Layout.fillWidth: true
                            value: Math.max(0, root.brightness) / 100
                            onMoved: v => root.setBrightness(v * 100)
                        }
                        Text {
                            text: root.brightness + "%"
                            color: root.fgDim
                            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 1 }
                            Layout.preferredWidth: 52
                        }
                    }
                    Text {
                        visible: root.brightness < 0
                        text: "no controllable backlight"
                        color: root.gray
                        font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 2 }
                    }

                    SectionLabel { text: "NIGHT LIGHT" }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: root.nightLight ? "󰛨" : "󰹏"
                            color: root.nightLight ? root.orange : root.fgDim
                            font { family: root.fontFamily; bold: true; pixelSize: root.iconSize }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.nightLight ? "on — 4000K warm tint" : "off — normal colors"
                            color: root.fg
                            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 1 }
                        }
                        TogglePill {
                            on: root.nightLight
                            onClicked: root.toggleNightLight()
                        }
                    }

                    SectionLabel { text: "FONT SIZE  (shell)" }
                    RowLayout {
                        spacing: 8
                        ActionChip {
                            label: "A−"
                            enabled: root.fontSize > 12
                            onClicked: root.setFontSize(root.fontSize - 1)
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.fontSize + " px"
                            horizontalAlignment: Text.AlignHCenter
                            color: root.fg
                            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize }
                        }
                        ActionChip {
                            label: "A+"
                            enabled: root.fontSize < 24
                            onClicked: root.setFontSize(root.fontSize + 1)
                        }
                    }

                    SectionLabel {
                        text: "MONITOR"
                        visible: Quickshell.screens.length > 1
                    }
                    RowLayout {
                        spacing: 6
                        visible: Quickshell.screens.length > 1
                        Repeater {
                            model: Quickshell.screens
                            ActionChip {
                                required property var modelData
                                label: modelData.name
                                accent: bar.dispTarget === modelData.name
                                Layout.fillWidth: true
                                onClicked: {
                                    bar.dispTarget = modelData.name;
                                    displayPopup.resOpen = false;
                                    dispInfo.running = true;
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        SectionLabel {
                            Layout.fillWidth: true
                            text: "OUTPUT  (" + bar.dispTarget + ")"
                        }
                        TogglePill {
                            // don't allow blacking out the last enabled monitor
                            enabled: !bar.outEnabled
                                     || bar.outAll.filter(o => o.enabled).length > 1
                            opacity: enabled ? 1 : 0.45
                            on: bar.outEnabled
                            onClicked: bar.applyEnabled(!bar.outEnabled)
                        }
                    }

                    SectionLabel { text: "SCALE  (" + bar.outScale.toFixed(2) + "×)" }
                    RowLayout {
                        spacing: 6
                        Repeater {
                            model: ["1", "1.25", "1.5", "1.75", "2"]
                            ActionChip {
                                required property var modelData
                                label: modelData + "×"
                                accent: Math.abs(bar.outScale - parseFloat(modelData)) < 0.01
                                Layout.fillWidth: true
                                onClicked: bar.applyScale(parseFloat(modelData))
                            }
                        }
                    }

                    SectionLabel { text: "RESOLUTION" }
                    // collapsed dropdown: current mode; click to expand the list
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        radius: 5
                        color: resHead.containsMouse ? root.bg2 : root.bg1
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            Text {
                                Layout.fillWidth: true
                                text: {
                                    const c = bar.outModes.find(m => m.current);
                                    return c ? c.w + "×" + c.h + "  @ " + Math.round(c.refresh) + "Hz"
                                             : (bar.outModes.length ? "select mode" : "wlr-randr not available");
                                }
                                color: root.fg
                                font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 1 }
                            }
                            Text {
                                text: displayPopup.resOpen ? "▴" : "▾"
                                color: root.fgDim
                                font { family: root.fontFamily; bold: true; pixelSize: root.fontSize }
                            }
                        }
                        MouseArea {
                            id: resHead
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: displayPopup.resOpen = !displayPopup.resOpen
                        }
                    }
                    Flickable {
                        visible: displayPopup.resOpen
                        Layout.fillWidth: true
                        implicitHeight: Math.min(170, modeCol.implicitHeight)
                        contentHeight: modeCol.implicitHeight
                        clip: true
                        ScrollBar.vertical: GruvScrollBar {}
                        ColumnLayout {
                            id: modeCol
                            width: parent.width
                            spacing: 2
                            Repeater {
                                model: bar.outModes
                                Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 32
                                    radius: 5
                                    color: modelData.current ? root.bg2
                                         : (modeMa.containsMouse ? root.bg1 : "transparent")
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.w + "×" + modelData.h
                                                  + "  @ " + Math.round(modelData.refresh) + "Hz"
                                            color: modelData.current ? root.fg0 : root.fg
                                            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 2 }
                                        }
                                        Text {
                                            visible: modelData.current
                                            text: "󰄬"
                                            color: root.green
                                            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 1 }
                                        }
                                    }
                                    MouseArea {
                                        id: modeMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            bar.applyMode(modelData);
                                            displayPopup.resOpen = false;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    SectionLabel { text: "ROTATION" }
                    RowLayout {
                        spacing: 6
                        Repeater {
                            model: [
                                { t: "normal", label: "0°" },
                                { t: "90",     label: "90°" },
                                { t: "180",    label: "180°" },
                                { t: "270",    label: "270°" }
                            ]
                            ActionChip {
                                required property var modelData
                                label: modelData.label
                                accent: bar.outTransform === modelData.t
                                Layout.fillWidth: true
                                onClicked: bar.applyTransform(modelData.t)
                            }
                        }
                    }

                    // position relative to another output (multi-monitor only)
                    SectionLabel {
                        text: "POSITION  (relative to " + displayPopup.posRef + ")"
                        visible: Quickshell.screens.length > 1
                    }
                    RowLayout {
                        spacing: 6
                        visible: Quickshell.screens.length > 1
                                 && bar.outAll.filter(o => o.name !== bar.dispTarget).length > 1
                        Repeater {
                            model: bar.outAll.filter(o => o.name !== bar.dispTarget)
                            ActionChip {
                                required property var modelData
                                label: modelData.name
                                accent: displayPopup.posRef === modelData.name
                                Layout.fillWidth: true
                                onClicked: displayPopup.posRef = modelData.name
                            }
                        }
                    }
                    RowLayout {
                        spacing: 6
                        visible: Quickshell.screens.length > 1
                        Repeater {
                            model: [
                                { d: "left",   label: "󰜱 left of" },
                                { d: "right",  label: "󰜴 right of" },
                                { d: "above",  label: "󰜷 above" },
                                { d: "below",  label: "󰜮 below" },
                                { d: "mirror", label: "󰍺 mirror" }
                            ]
                            ActionChip {
                                required property var modelData
                                label: modelData.label
                                Layout.fillWidth: true
                                onClicked: bar.placeRelative(modelData.d, displayPopup.posRef)
                            }
                        }
                    }
                }
            }

            // ---------- battery popup (info + power profile) ----------            // ---------- battery popup (info + power profile) ----------
            PanelWindow {
                id: batteryPopup
                screen: perScreen.modelData
                anchors { top: true; left: true }
                margins { top: root.barHeight + 4; left: 8 }
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                implicitWidth: 310
                implicitHeight: batCol.implicitHeight + 28
                visible: false
                color: root.bg0h

                ColumnLayout {
                    id: batCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                    spacing: 8
                    readonly property var dev: UPower.displayDevice

                    SectionLabel { text: "BATTERY" }
                    MonRow {
                        label: "charge"
                        pct: batCol.dev ? batCol.dev.percentage * 100 : 0
                        barColor: batCol.dev && batCol.dev.state === UPowerDeviceState.Charging
                                  ? root.aqua : (pct < 20 ? root.red : root.green)
                    }
                    InfoPair {
                        label: "state"
                        value: batCol.dev ? root.batStateText(batCol.dev.state) : "—"
                    }
                    InfoPair {
                        label: batCol.dev && batCol.dev.state === UPowerDeviceState.Charging
                               ? "time to full" : "time left"
                        value: {
                            const d = batCol.dev;
                            if (!d) return "—";
                            return root.fmtSecs(d.state === UPowerDeviceState.Charging
                                                ? d.timeToFull : d.timeToEmpty);
                        }
                    }
                    InfoPair {
                        label: "power draw"
                        value: batCol.dev && batCol.dev.changeRate > 0
                               ? batCol.dev.changeRate.toFixed(1) + " W" : "—"
                    }
                    InfoPair {
                        label: "health"
                        value: root.batHealth > 0 ? root.batHealth.toFixed(0) + "%" : "—"
                    }
                    InfoPair {
                        label: "capacity"
                        value: batCol.dev && batCol.dev.energyCapacity > 0
                               ? batCol.dev.energyCapacity.toFixed(1) + " Wh" : "—"
                    }
                    InfoPair {
                        label: "charge cycles"
                        value: root.batCycles > 0 ? String(root.batCycles) : "—"
                    }

                    SectionLabel { text: "POWER PROFILE" }
                    Repeater {
                        model: [
                            { p: PowerProfile.PowerSaver,  icon: "󰾆", label: "power saver" },
                            { p: PowerProfile.Balanced,    icon: "󰾅", label: "balanced" },
                            { p: PowerProfile.Performance, icon: "󰓅", label: "performance" }
                        ]
                        Rectangle {
                            required property var modelData
                            readonly property bool current: PowerProfiles.profile === modelData.p
                            visible: modelData.p !== PowerProfile.Performance
                                     || PowerProfiles.hasPerformanceProfile
                            Layout.fillWidth: true
                            implicitHeight: 36
                            radius: 5
                            color: current ? root.bg2 : (ppMa.containsMouse ? root.bg1 : "transparent")
                            border.width: current ? 1 : 0
                            border.color: root.aqua
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8
                                Text {
                                    text: modelData.icon
                                    color: parent.parent.current ? root.aqua : root.fgDim
                                    font { family: root.fontFamily; bold: true; pixelSize: root.fontSize + 2 }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.label
                                    color: parent.parent.current ? root.fg0 : root.fg
                                    elide: Text.ElideRight
                                    font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 1 }
                                }
                                Text {
                                    visible: parent.parent.current
                                    text: "󰄬"
                                    color: root.green
                                    font { family: root.fontFamily; bold: true; pixelSize: root.fontSize }
                                }
                            }
                            MouseArea {
                                id: ppMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: PowerProfiles.profile = modelData.p
                            }
                        }
                    }
                }
            }

            // ---------- system info popup ----------
            PanelWindow {
                id: sysPopup
                screen: perScreen.modelData
                anchors { top: true; left: true }
                margins { top: root.barHeight + 4; left: 8 }
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                implicitWidth: 340
                implicitHeight: sysCol.implicitHeight + 28
                visible: false
                color: root.bg0h

                ColumnLayout {
                    id: sysCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                    spacing: 8

                    SectionLabel { text: "SYSTEM" }
                    MonRow {
                        label: "cpu"
                        pct: root.cpuPct
                        barColor: root.aqua
                        detail: root.cpuMhz > 0
                                ? Math.round(root.cpuPct) + "% · " + (root.cpuMhz / 1000).toFixed(2) + " GHz"
                                : ""
                    }
                    MonRow { label: "ram";  pct: root.memPct;  barColor: root.blue; detail: root.memUsedG.toFixed(1) + "G / " + root.memTotalG.toFixed(1) + "G" }
                    MonRow { label: "disk"; pct: root.diskPct; barColor: root.purple; detail: root.diskUsed + " / " + root.diskAvail }
                    MonRow {
                        visible: root.gpuPct >= 0
                        label: "gpu"; pct: root.gpuPct; barColor: root.orange
                        detail: root.gpuMemTotal > 0
                                ? root.gpuMemUsed.toFixed(1) + "G / " + root.gpuMemTotal.toFixed(1) + "G"
                                : ""
                    }
                    InfoPair { label: "net down"; value: root.fmtRate(root.netRx) }
                    InfoPair { label: "net up";   value: root.fmtRate(root.netTx) }
                    ActionChip {
                        label: "open btop"
                        Layout.alignment: Qt.AlignHCenter
                        onClicked: {
                            Quickshell.execDetached(["kitty", "--class", "btop", "-e", "btop"]);
                            bar.closeAllPopups();
                        }
                    }
                }
            }

            // ---------- notification center ----------            // ---------- notification center ----------
            PopupWindow {
                id: notifPopup
                anchor.window: bar
                anchor.rect.x: bar.width - 440
                anchor.rect.y: root.barHeight
                implicitWidth: 430
                implicitHeight: 520
                visible: false
                color: root.bg0h

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Notifications"
                            color: root.yellow
                            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize }
                        }
                        Text {
                            text: "dnd"
                            color: root.doNotDisturb ? root.red : root.fgDim
                            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 3 }
                        }
                        TogglePill {
                            on: root.doNotDisturb
                            onClicked: root.doNotDisturb = !root.doNotDisturb
                        }
                        Rectangle {
                            implicitWidth: 100; implicitHeight: 30; radius: 5
                            color: caMa.containsMouse ? root.bg2 : root.bg1
                            Text {
                                anchors.centerIn: parent
                                text: "clear all"
                                color: root.fgDim
                                font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 2 }
                            }
                            MouseArea {
                                id: caMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: notifHistory.clear()
                            }
                        }
                    }
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 6
                        ScrollBar.vertical: GruvScrollBar {}
                        model: notifHistory
                        delegate: Rectangle {
                            required property var model
                            width: ListView.view.width
                            height: nhCol.implicitHeight + 16
                            radius: 6
                            color: root.bg1
                            ColumnLayout {
                                id: nhCol
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                                spacing: 2
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        Layout.fillWidth: true
                                        text: model.nApp + (model.nSummary ? "  ·  " + model.nSummary : "")
                                        color: root.fg
                                        elide: Text.ElideRight
                                        font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 1 }
                                    }
                                    Text {
                                        text: model.nTime
                                        color: root.gray
                                        font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 3 }
                                    }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    visible: model.nBody !== ""
                                    text: model.nBody
                                    color: root.fgDim
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                    textFormat: Text.PlainText
                                    font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 2 }
                                }
                            }
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: notifHistory.count === 0
                            text: "all caught up"
                            color: root.gray
                            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize }
                        }
                    }
                }
            }

            // ---------- clipboard history ----------
            PopupWindow {
                id: clipPopup
                anchor.window: bar
                anchor.rect.x: bar.width - 490
                anchor.rect.y: root.barHeight
                implicitWidth: 480
                implicitHeight: 460
                visible: false
                color: root.bg0h

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6
                    Text {
                        text: "Clipboard history  (click to copy)"
                        color: root.purple
                        font { family: root.fontFamily; bold: true; pixelSize: root.fontSize }
                    }
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 2
                        ScrollBar.vertical: GruvScrollBar {}
                        model: root.clipEntries
                        delegate: Rectangle {
                            required property var modelData
                            width: ListView.view.width
                            height: 38
                            radius: 5
                            color: clMa.containsMouse ? root.bg1 : "transparent"
                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                verticalAlignment: Text.AlignVCenter
                                text: modelData.preview
                                color: root.fg
                                elide: Text.ElideRight
                                textFormat: Text.PlainText
                                font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 1 }
                            }
                            MouseArea {
                                id: clMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    root.copyClip(modelData.cid);
                                    clipPopup.visible = false;
                                }
                            }
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: root.clipEntries.length === 0
                            text: "empty — is `wl-paste --watch cliphist store` running?"
                            color: root.gray
                            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 1 }
                        }
                    }
                }
            }

            // ---------- calendar (browsable) ----------
            PopupWindow {
                id: calPopup
                anchor.window: bar
                anchor.rect.x: bar.width - 400
                anchor.rect.y: root.barHeight
                implicitWidth: 390
                implicitHeight: 420
                visible: false
                color: root.bg0h

                property int viewMonth: clock.date.getMonth()
                property int viewYear: clock.date.getFullYear()
                onVisibleChanged: if (visible) {
                    viewMonth = clock.date.getMonth();
                    viewYear = clock.date.getFullYear();
                }
                function shiftMonth(d) {
                    let m = viewMonth + d;
                    while (m < 0)  { m += 12; viewYear--; }
                    while (m > 11) { m -= 12; viewYear++; }
                    viewMonth = m;
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    // ---- header: « ‹ Month Year › » + today ----
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        CalNavButton { text: "«"; onClicked: calPopup.viewYear-- }
                        CalNavButton { text: "‹"; onClicked: calPopup.shiftMonth(-1) }
                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 32
                            Text {
                                anchors.centerIn: parent
                                text: Qt.locale().monthName(calPopup.viewMonth) + " " + calPopup.viewYear
                                color: root.yellow
                                font { family: root.fontFamily; bold: true; pixelSize: root.fontSize + 1 }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    calPopup.viewMonth = clock.date.getMonth();
                                    calPopup.viewYear = clock.date.getFullYear();
                                }
                            }
                        }
                        CalNavButton { text: "›"; onClicked: calPopup.shiftMonth(1) }
                        CalNavButton { text: "»"; onClicked: calPopup.viewYear++ }
                    }

                    DayOfWeekRow {
                        Layout.fillWidth: true
                        delegate: Text {
                            required property var model
                            text: model.shortName
                            color: root.fgDim
                            horizontalAlignment: Text.AlignHCenter
                            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 2 }
                        }
                    }

                    MonthGrid {
                        id: calGrid
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        month: calPopup.viewMonth
                        year: calPopup.viewYear
                        delegate: Item {
                            id: dayCell
                            required property var model
                            readonly property bool inMonth: model.month === calGrid.month

                            Rectangle {
                                id: dayBg
                                anchors.centerIn: parent
                                width: 34; height: 34; radius: 17
                                color: model.today ? root.yellow
                                     : dayMa.containsMouse ? root.bg2
                                     : "transparent"
                                scale: dayMa.containsMouse ? 1.12 : 1.0
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Behavior on scale {
                                    NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
                                }
                            }
                            Text {
                                anchors.centerIn: parent
                                text: model.day
                                opacity: dayCell.inMonth ? 1 : (dayMa.containsMouse ? 0.7 : 0.3)
                                color: model.today ? root.bg0
                                     : dayMa.containsMouse ? root.fg0
                                     : root.fg
                                font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 1 }
                                Behavior on opacity { NumberAnimation { duration: 120 } }
                            }
                            MouseArea {
                                id: dayMa
                                anchors.fill: parent
                                hoverEnabled: true
                                // click a spillover day -> browse to its month
                                onClicked: if (!dayCell.inMonth) {
                                    calPopup.viewMonth = dayCell.model.month;
                                    calPopup.viewYear = dayCell.model.year;
                                }
                            }
                        }
                    }

                    // today shortcut
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 110; implicitHeight: 30; radius: 6
                        color: todayMa.containsMouse ? root.bg2 : root.bg1
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            anchors.centerIn: parent
                            text: Qt.formatDate(clock.date, "dd MMM yyyy")
                            color: root.fgDim
                            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 3 }
                        }
                        MouseArea {
                            id: todayMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                calPopup.viewMonth = clock.date.getMonth();
                                calPopup.viewYear = clock.date.getFullYear();
                            }
                        }
                    }
                }
            }

            // ---------- tray menu (rendered in-shell; native menus are
            //            unreliable on wlroots layer-shell) ----------
            PopupWindow {
                id: trayMenuPopup
                anchor.window: bar
                anchor.rect.y: root.barHeight
                implicitWidth: 280
                implicitHeight: Math.min(560, trayMenuCol.implicitHeight + 16)
                visible: false
                color: root.bg0h

                QsMenuOpener {
                    id: trayOpener
                    menu: bar.trayMenuHandle
                }

                ColumnLayout {
                    id: trayMenuCol
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 2

                    Repeater {
                        model: trayOpener.children
                        delegate: ColumnLayout {
                            id: menuNode
                            required property var modelData
                            property bool expanded: false
                            Layout.fillWidth: true
                            spacing: 2

                            TrayMenuRow {
                                entry: menuNode.modelData
                                submenuOpen: menuNode.expanded
                                onActivated: {
                                    if (menuNode.modelData.hasChildren) {
                                        menuNode.expanded = !menuNode.expanded;
                                    } else {
                                        menuNode.modelData.triggered();
                                        bar.closeAllPopups();
                                    }
                                }
                            }

                            QsMenuOpener {
                                id: subOpener
                                menu: menuNode.modelData
                            }
                            Repeater {
                                model: menuNode.expanded ? subOpener.children : null
                                delegate: TrayMenuRow {
                                    required property var modelData
                                    entry: modelData
                                    Layout.leftMargin: 22
                                    onActivated: {
                                        modelData.triggered();
                                        bar.closeAllPopups();
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: trayOpener.children.values.length === 0
                        text: "no actions"
                        color: root.gray
                        Layout.margins: 8
                        font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 1 }
                    }
                }
            }

            // ---------- power menu ----------
            PopupWindow {
                id: powerPopup
                anchor.window: bar
                anchor.rect.x: bar.width - 210
                anchor.rect.y: root.barHeight
                implicitWidth: 200
                implicitHeight: powerCol.implicitHeight + 16
                visible: false
                color: root.bg0h

                ColumnLayout {
                    id: powerCol
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4
                    PowerAction { label: "󰌾  Lock";       cmd: ["sh", "-c", "kitty --class screensaver --start-as fullscreen -o background_opacity=1 bash \"$HOME/.local/bin/screensaver.sh\""]; popup: powerPopup }
                    PowerAction { label: "󰜉  Reboot";     cmd: ["systemctl", "reboot"];         popup: powerPopup }
                    PowerAction { label: "⏻  Shutdown";   cmd: ["systemctl", "poweroff"];       popup: powerPopup }
                    PowerAction { label: "󰗼  Exit mango"; cmd: ["mmsg", "dispatch", "quit"];    popup: powerPopup }
                }
            }
            }

            // transparent fullscreen catcher: click anywhere outside -> close popups
            PanelWindow {
                screen: perScreen.modelData
                visible: bar.anyPopupOpen
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Top
                anchors { top: true; bottom: true; left: true; right: true }
                margins.top: root.barHeight
                color: "transparent"
                MouseArea {
                    anchors.fill: parent
                    onClicked: bar.closeAllPopups()
                }
            }
        }
    }

    // ======================================================================
    //                    reusable components (root level)
    // ======================================================================

    component BarButton: Rectangle {
        property string text
        property color fgColor: root.fg
        property string tooltip: ""
        property int px: root.fontSize
        signal clicked()
        signal rightClicked()
        signal middleClicked()
        implicitWidth: btnText.width + 18
        implicitHeight: 30
        radius: 4
        color: btnMa.containsMouse ? root.bg1 : "transparent"
        Text {
            id: btnText
            anchors.centerIn: parent
            text: parent.text
            color: parent.fgColor
            font { family: root.fontFamily; bold: true; pixelSize: parent.px }
        }
        MouseArea {
            id: btnMa
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: ev => {
                if (ev.button === Qt.RightButton) parent.rightClicked();
                else if (ev.button === Qt.MiddleButton) parent.middleClicked();
                else parent.clicked();
            }
        }
        ToolTip.visible: tooltip !== "" && btnMa.containsMouse
        ToolTip.text: tooltip
        ToolTip.delay: 600
    }

    component PowerAction: Rectangle {
        property string label
        property var cmd
        property var popup
        Layout.fillWidth: true
        implicitHeight: 36
        radius: 5
        color: paMa.containsMouse ? root.bg2 : "transparent"
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 8
            text: parent.label
            color: root.fg
            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize }
        }
        MouseArea {
            id: paMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                Quickshell.execDetached(parent.cmd);
                if (parent.popup) parent.popup.visible = false;
            }
        }
    }

    component TrayMenuRow: Rectangle {
        property var entry
        property bool submenuOpen: false
        signal activated()
        readonly property bool sep: entry ? entry.isSeparator : false
        Layout.fillWidth: true
        implicitHeight: sep ? 9 : 36
        radius: 4
        color: !sep && rowMa.containsMouse && entry && entry.enabled ? root.bg2 : "transparent"

        Rectangle {
            visible: parent.sep
            anchors.centerIn: parent
            width: parent.width - 8
            height: 1
            color: root.bg2
        }
        RowLayout {
            visible: !parent.sep
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8
            Text {
                visible: text !== ""
                text: parent.parent.entry && parent.parent.entry.checkState === Qt.Checked ? "󰄬" : ""
                color: root.green
                font { family: root.fontFamily; bold: true; pixelSize: root.fontSize }
            }
            IconImage {
                visible: parent.parent.entry && parent.parent.entry.icon !== ""
                source: parent.parent.entry ? parent.parent.entry.icon : ""
                implicitSize: 20
            }
            Text {
                Layout.fillWidth: true
                text: parent.parent.entry ? parent.parent.entry.text.replace(/&/g, "") : ""
                color: parent.parent.entry && parent.parent.entry.enabled ? root.fg : root.gray
                elide: Text.ElideRight
                font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 1 }
            }
            Text {
                visible: parent.parent.entry ? parent.parent.entry.hasChildren : false
                text: parent.parent.submenuOpen ? "⌄" : "›"
                color: root.fgDim
                font { family: root.fontFamily; bold: true; pixelSize: root.fontSize }
            }
        }
        MouseArea {
            id: rowMa
            anchors.fill: parent
            hoverEnabled: true
            enabled: parent.entry ? (parent.entry.enabled && !parent.sep) : false
            onClicked: parent.activated()
        }
    }

    component GruvScrollBar: ScrollBar {
        id: sb
        policy: ScrollBar.AsNeeded
        contentItem: Rectangle {
            implicitWidth: 8
            radius: 4
            color: sb.pressed ? root.yellow : (sb.hovered ? root.bg3 : root.bg2)
        }
        background: Rectangle {
            implicitWidth: 8
            radius: 4
            color: root.bg0
        }
    }

    component TogglePill: Rectangle {
        property bool on: false
        signal clicked()
        implicitWidth: 64
        implicitHeight: 28
        radius: 14
        color: on ? root.green : root.bg2
        Rectangle {
            width: 22; height: 22; radius: 11
            anchors.verticalCenter: parent.verticalCenter
            x: parent.on ? parent.width - width - 3 : 3
            color: root.fg0
            Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            x: parent.on ? 8 : parent.width - width - 8
            text: parent.on ? "on" : "off"
            color: parent.on ? root.bg0 : root.fgDim
            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 4 }
        }
        MouseArea { anchors.fill: parent; onClicked: parent.clicked() }
    }

    component ActionChip: Rectangle {
        property string label
        property bool accent: false
        signal clicked()
        opacity: enabled ? 1 : 0.45
        implicitWidth: chipText.width + 20
        implicitHeight: 30
        radius: 5
        color: accent ? root.yellow : (acMa.containsMouse && enabled ? root.bg2 : root.bg1)
        Text {
            id: chipText
            anchors.centerIn: parent
            text: parent.label
            color: parent.accent ? root.bg0 : root.fg
            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 2 }
        }
        MouseArea {
            id: acMa
            anchors.fill: parent
            hoverEnabled: true
            enabled: parent.enabled
            onClicked: parent.clicked()
        }
    }

    component StatusPill: Rectangle {
        property string icon
        property string value
        property color iconColor: root.fg0
        property int maxValueWidth: 400
        property string tooltip: ""
        signal clicked()
        signal rightClicked()
        signal wheelMoved(real delta)
        implicitWidth: pillRow.implicitWidth + 16
        implicitHeight: 30
        radius: 4
        color: pillMa.containsMouse ? root.bg1 : "transparent"
        RowLayout {
            id: pillRow
            anchors.centerIn: parent
            spacing: 6
            Text {
                text: parent.parent.icon
                color: parent.parent.iconColor
                font { family: root.fontFamily; bold: true; pixelSize: root.iconSize - 2 }
            }
            Text {
                text: parent.parent.value
                color: root.fg
                elide: Text.ElideRight
                Layout.maximumWidth: parent.parent.maxValueWidth
                font { family: root.fontFamily; bold: true; pixelSize: root.fontSize }
            }
        }
        MouseArea {
            id: pillMa
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: ev => ev.button === Qt.RightButton ? parent.rightClicked() : parent.clicked()
            onWheel: ev => parent.wheelMoved(ev.angleDelta.y)
        }
        ToolTip.visible: tooltip !== "" && pillMa.containsMouse
        ToolTip.text: tooltip
        ToolTip.delay: 700
    }

    component ChipStat: RowLayout {
        property string icon
        property string value
        spacing: 5
        Text {
            text: parent.icon
            color: root.fg0
            font { family: root.fontFamily; bold: true; pixelSize: root.iconSize - 2 }
        }
        Text {
            text: parent.value
            color: root.fg
            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize }
        }
    }

    component InfoPair: RowLayout {
        property string label
        property string value
        Layout.fillWidth: true
        spacing: 8
        Text {
            text: parent.label
            color: root.fgDim
            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 2 }
            Layout.preferredWidth: 150
        }
        Text {
            Layout.fillWidth: true
            text: parent.value
            color: root.fg
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignRight
            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 2 }
        }
    }

    component MonRow: RowLayout {
        property string label
        property real pct: 0        // 0..100
        property string detail: ""  // overrides the % text when set
        property color barColor: root.aqua
        spacing: 8
        Layout.fillWidth: true
        Text {
            text: parent.label
            color: root.fgDim
            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 2 }
            Layout.preferredWidth: 56
        }
        Item {
            Layout.fillWidth: true
            implicitHeight: 10
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width; height: 8; radius: 4
                color: root.bg2
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(0, Math.min(100, parent.parent.pct)) / 100 * parent.width
                height: 8; radius: 4
                color: parent.parent.pct > 90 ? root.red : parent.parent.barColor
                Behavior on width { NumberAnimation { duration: 300 } }
            }
        }
        Text {
            text: parent.detail !== "" ? parent.detail : Math.round(parent.pct) + "%"
            color: root.fg
            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 2 }
            Layout.preferredWidth: parent.detail !== "" ? 130 : 52
            horizontalAlignment: Text.AlignRight
        }
    }

    component CalNavButton: Rectangle {
        property string text
        signal clicked()
        implicitWidth: 32
        implicitHeight: 32
        radius: 6
        color: navMa.containsMouse ? root.bg2 : root.bg1
        Behavior on color { ColorAnimation { duration: 120 } }
        Text {
            anchors.centerIn: parent
            text: parent.text
            color: root.fg
            font { family: root.fontFamily; bold: true; pixelSize: root.fontSize + 2 }
        }
        MouseArea {
            id: navMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.clicked()
        }
    }

    component SectionLabel: Text {
        color: root.gray
        font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 3; letterSpacing: 1 }
        Layout.fillWidth: true
        Layout.topMargin: 4
    }

    component GruvSlider: Item {
        id: slider
        property real value: 0            // 0..1
        signal moved(real v)
        implicitHeight: 26
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 5
            radius: 2.5
            color: root.bg2
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, Math.min(1, slider.value)) * parent.width
            height: 5
            radius: 2.5
            color: root.yellow
        }
        Rectangle {
            x: Math.max(0, Math.min(1, slider.value)) * (parent.width - width)
            anchors.verticalCenter: parent.verticalCenter
            width: 18; height: 18; radius: 9
            color: root.fg
            border.width: 2
            border.color: root.bg0
        }
        MouseArea {
            anchors.fill: parent
            function emitPos(mx) { slider.moved(Math.max(0, Math.min(1, mx / slider.width))) }
            onPressed: ev => emitPos(ev.x)
            onPositionChanged: ev => { if (pressed) emitPos(ev.x) }
        }
    }

    component QsToggle: Rectangle {
        property string icon
        property string label
        property bool active: false
        signal toggled()
        Layout.fillWidth: true
        implicitHeight: 64
        radius: 8
        color: active ? root.bg2 : (qtMa.containsMouse ? root.bg1 : root.bg0)
        border.width: 1
        border.color: active ? root.yellow : root.bg2
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 1
            Text {
                text: parent.parent.icon
                color: parent.parent.active ? root.yellow : root.fgDim
                font { family: root.fontFamily; bold: true; pixelSize: root.iconSize }
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: parent.parent.label
                color: parent.parent.active ? root.fg : root.gray
                font { family: root.fontFamily; bold: true; pixelSize: root.fontSize - 3 }
                Layout.alignment: Qt.AlignHCenter
            }
        }
        MouseArea {
            id: qtMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.toggled()
        }
    }
}
