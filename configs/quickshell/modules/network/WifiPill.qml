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
            ? (Net.netSsid !== "" ? Net.netSsid : "connected")   // never the
              // route iface: under a VPN that's the tunnel device's
              // auto-generated name (the "weird numbers")
            : Net.netIface)
    maxValueWidth: 150
    tooltip: "network"
    onClicked: {
        bar.togglePopupAt(popup, wifiPill);
        if (popup.visible && Net.wifiEnabled) Net.scanWifi();
    }
}
