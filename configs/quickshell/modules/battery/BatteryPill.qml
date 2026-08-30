import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../Services"
import "../../Widgets"
import Quickshell.Services.UPower

StatusPill {
    required property var bar
    required property var popup
    id: batteryPill
    readonly property var bat: UPower.displayDevice
    readonly property bool charging: bat && bat.state === UPowerDeviceState.Charging
    visible: bat !== null && bat.isLaptopBattery
    icon: bat ? Theme.batIcon(bat.percentage * 100, charging) : "󰁹"
    iconColor: charging ? Theme.aqua
             : (bat && bat.percentage < 0.2 ? Theme.red : Theme.green)
    value: bat ? Math.round(bat.percentage * 100) + "%" : ""
    tooltip: "battery & power profile"
    onClicked: bar.togglePopupAt(popup, batteryPill)
}
