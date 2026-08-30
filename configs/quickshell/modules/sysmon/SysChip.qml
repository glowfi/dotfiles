import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../Services"
import "../../Widgets"

Rectangle {
    required property var bar
    required property var popup
    id: sysChip
    implicitWidth: chipRow.implicitWidth + 20
    implicitHeight: 30
    radius: 4
    color: chipMa.containsMouse ? Theme.bg1 : "transparent"

    RowLayout {
        id: chipRow
        anchors.centerIn: parent
        spacing: 12

        ChipStat {
            icon: "󰻠"
            value: Math.round(SysMon.cpuPct) + "%"
                   + (SysMon.cpuMhz > 0 ? " " + (SysMon.cpuMhz / 1000).toFixed(1) + "GHz" : "")
        }
        ChipStat { icon: "󰍛"; value: SysMon.memUsedG.toFixed(1) + "/" + SysMon.memTotalG.toFixed(0) + "G" }
        ChipStat { icon: "󰋊"; value: SysMon.diskUsed + "/" + SysMon.diskAvail }
        ChipStat { icon: "󰇚"; value: SysMon.fmtRateShort(SysMon.netRx) }
        ChipStat { icon: "󰕒"; value: SysMon.fmtRateShort(SysMon.netTx) }
    }
    MouseArea {
        id: chipMa
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: ev => {
            if (ev.button === Qt.RightButton) bar.togglePopupAt(popup, sysChip);
            else Quickshell.execDetached(["kitty", "--class", "btop", "-e", "btop"]);
        }
    }
    ToolTip.visible: chipMa.containsMouse
    ToolTip.text: "click: btop · right-click: system info"
    ToolTip.delay: 700
}
