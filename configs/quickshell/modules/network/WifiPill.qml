import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Services"
import "../../Widgets"

StatusPill {
    required property var bar
    required property var popup
    id: wifiPill
    icon: Net.netIface === "" ? "󰖪"
        : (Net.netIface.startsWith("w") ? Theme.wifiIcon(Net.netSignal) : "󰈀")
    iconColor: Net.netIface === "" ? Theme.red : Theme.green
    value: Net.netIface === "" ? "off"
         : (Net.netIface.startsWith("w")
            ? (Net.netSsid !== "" ? Net.netSsid : Net.netIface)
            : Net.netIface)
    maxValueWidth: 150
    tooltip: "network"
    onClicked: {
        bar.togglePopupAt(popup, wifiPill);
        if (popup.visible && Net.wifiEnabled) Net.scanWifi();
    }
}
