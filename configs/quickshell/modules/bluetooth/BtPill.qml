import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Services"
import "../../Widgets"
import Quickshell.Bluetooth

StatusPill {
    required property var bar
    required property var popup
    id: btPill
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var connectedDev: {
        if (!adapter || !adapter.enabled) return null;
        for (const d of adapter.devices.values) if (d.connected) return d;
        return null;
    }
    visible: adapter !== null
    icon: !adapter || !adapter.enabled ? "󰂲" : (connectedDev ? "󰂱" : "󰂯")
    iconColor: !adapter || !adapter.enabled ? Theme.gray
             : (connectedDev ? Theme.blue : Theme.fg0)
    // battery of the connected device ON the pill, from either source
    readonly property int connectedPct: {
        if (!connectedDev) return -1;
        if (connectedDev.batteryAvailable ?? false)
            return Math.round((connectedDev.battery ?? 0) * 100);
        return BtCtl.battOf(connectedDev.address);
    }
    value: !adapter || !adapter.enabled ? "off"
         : !connectedDev ? "on"
         : connectedDev.name + (connectedPct >= 0 ? " · " + connectedPct + "%" : "")
    maxValueWidth: 170
    tooltip: {
        const a = Bluetooth.defaultAdapter;
        if (!a || !a.enabled) return "bluetooth off";
        const c = [...a.devices.values].filter(d => d.connected);
        if (c.length === 0) return "bluetooth — nothing connected";
        return c.map(d => {
            const pct = (d.batteryAvailable ?? false)
                ? Math.round((d.battery ?? 0) * 100) : BtCtl.battOf(d.address);
            return (d.name || d.address) + (pct >= 0 ? " · " + pct + "%" : "");
        }).join(", ");
    }
    onClicked: bar.togglePopupAt(popup, btPill)
}
