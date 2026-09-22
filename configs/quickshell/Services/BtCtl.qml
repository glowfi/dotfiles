pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

// Bluetooth control on PROVEN primitives only (execDetached one-shots — the
// bluetoothctl log confirmed these execute):
//   - races between one-shots ("Error.InProgress") are prevented by flock:
//     one bt operation at a time, extra clicks are no-ops while busy
//   - a long-lived `bluetoothctl --agent NoInputNoOutput` holds a pairing
//     agent so pairings create REAL bonds (no more "Paired: no" after
//     disconnect — the blueman difference)
//   - busyAddr/busyAction feed visible per-row status in the popup
Singleton {
    id: btCtl

    property bool scanning: false
    property var knownAddrs: []
    property string busyAddr: ""
    property string busyAction: ""

    function isKnown(addr) { return knownAddrs.indexOf(addr) !== -1 }

    // ---- pairing agent holder: its mere existence registers the agent ----
    Process {
        id: agentHold
        command: ["bluetoothctl", "--agent", "NoInputNoOutput"]
        running: true
        stdout: StdioCollector {}
        onExited: agentRestart.start()
    }
    Timer { id: agentRestart; interval: 10000; onTriggered: agentHold.running = true }

    function _busy(addr, action) {
        busyAddr = addr; busyAction = action;
        busyClear.restart(); knownKick.restart();
    }
    Timer {
        id: busyClear; interval: 20000
        onTriggered: { btCtl.busyAddr = ""; btCtl.busyAction = "" }
    }
    function clearBusy() { busyAddr = ""; busyAction = ""; busyClear.stop() }

    function pairDevice(addr) {
        if (busyAddr !== "") return;          // one operation at a time
        _busy(addr, "pairing…");
        Quickshell.execDetached(["sh", "-c",
            "exec 9>/tmp/btctl.lock; flock -n 9 || exit 0; " +
            "{ bluetoothctl --timeout 25 pair \"$1\"; bluetoothctl trust \"$1\"; " +
            "sleep 1; bluetoothctl connect \"$1\"; } >>/tmp/btctl.log 2>&1 " +
            "|| notify-send bluetooth \"pair/connect failed — /tmp/btctl.log\"",
            "_", addr]);
    }

    function connectDevice(addr) {
        if (busyAddr !== "") return;
        _busy(addr, "connecting…");
        Quickshell.execDetached(["sh", "-c",
            "exec 9>/tmp/btctl.lock; flock -n 9 || exit 0; " +
            "{ bluetoothctl trust \"$1\"; bluetoothctl connect \"$1\"; } " +
            ">>/tmp/btctl.log 2>&1 " +
            "|| notify-send bluetooth \"connect failed — /tmp/btctl.log\"",
            "_", addr]);
    }

    function scan() {
        if (scanning) return;
        scanning = true;
        Quickshell.execDetached(["sh", "-c",
            "bluetoothctl --timeout 12 scan on >/dev/null 2>&1"]);
        scanOff.restart();
    }
    Timer {
        id: scanOff
        interval: 12500
        onTriggered: {
            btCtl.scanning = false;
            // a natively-started discovery has no owner to stop it — end any
            // lingering one so "scanning…" cannot stick forever
            const ad = Bluetooth.defaultAdapter;
            if (ad && ad.discovering) {
                try { ad.discovering = false; } catch (e) {}
            }
        }
    }

    // battery per connected device, read from bluetoothctl (independent of
    // quickshell's device-property surface, which varies by build):
    // { "AA:BB:...": 82, ... }
    property var batteries: ({})
    Process {
        id: battProc
        command: ["sh", "-c",
            "for a in $(bluetoothctl devices Connected 2>/dev/null | awk '{print $2}'); do " +
            "p=$(bluetoothctl info \"$a\" 2>/dev/null " +
            "| sed -n 's/.*Battery Percentage:.*(\\([0-9]*\\)).*/\\1/p'); " +
            "[ -n \"$p\" ] && echo \"$a|$p\"; done"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const m = {};
                for (const line of text.trim().split("\n")) {
                    const p = line.split("|");
                    if (p.length === 2) m[p[0]] = parseInt(p[1]);
                }
                btCtl.batteries = m;
            }
        }
    }
    function battOf(addr) {
        return batteries[addr] !== undefined ? batteries[addr] : -1;
    }

    // sticky session union of everything BlueZ ever listed as paired/bonded
    function refreshKnown() { knownProc.running = true; battProc.running = true }
    Timer { id: knownKick; interval: 2500; onTriggered: btCtl.refreshKnown() }
    Process {
        id: knownProc
        command: ["sh", "-c",
            "{ bluetoothctl devices Paired; bluetoothctl devices Bonded; " +
            "bluetoothctl paired-devices; } 2>/dev/null " +
            "| awk '/^Device/ { print $2 }' | sort -u"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const merged = btCtl.knownAddrs.slice();
                for (const a of text.trim().split("\n"))
                    if (a !== "" && merged.indexOf(a) === -1) merged.push(a);
                btCtl.knownAddrs = merged;
            }
        }
    }
}
