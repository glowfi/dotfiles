import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../Services"
import "../../Widgets"

StatusPill {
    required property var bar
    required property var popup
    id: displayPill
    icon: "󰍹"
    iconColor: DisplayCtl.nightLight ? Theme.orange : Theme.fg0
    value: DisplayCtl.brightness >= 0 ? DisplayCtl.brightness + "%" : ""
    tooltip: "display — brightness & night light"
    onClicked: bar.togglePopupAt(popup, displayPill)
    onWheelMoved: d => DisplayCtl.adjustFromWheel(d)
}
