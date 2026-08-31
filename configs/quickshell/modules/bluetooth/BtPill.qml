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
    value: !adapter || !adapter.enabled ? "off"
         : (connectedDev ? connectedDev.name : "on")
    maxValueWidth: 130
    tooltip: "bluetooth"
    onClicked: bar.togglePopupAt(popup, btPill)
}
