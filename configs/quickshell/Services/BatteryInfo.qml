pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: batteryInfo

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
                batCycles = p[0];
                batHealth = (p[1] > 0 && p[2] > 0) ? 100 * p[1] / p[2] : -1;
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


    Timer { interval: 30000; running: true; repeat: true; onTriggered: batExtra.running = true }
}
