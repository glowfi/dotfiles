import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../Services"
import "../../Widgets"
import Quickshell.Wayland

PanelWindow {
    required property var bar
    id: sysPopup
    screen: bar.screen
    anchors { top: true; left: true }
    margins { top: Theme.barHeight + 4; left: 8 }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    implicitWidth: 340
    implicitHeight: sysCol.implicitHeight + 28
    visible: false
    color: Theme.bg0h

    ColumnLayout {
        id: sysCol
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        spacing: 8

        SectionLabel { text: "SYSTEM" }
        MonRow {
            label: "cpu"
            pct: SysMon.cpuPct
            barColor: Theme.aqua
            detail: SysMon.cpuMhz > 0
                    ? Math.round(SysMon.cpuPct) + "% · " + (SysMon.cpuMhz / 1000).toFixed(2) + " GHz"
                    : ""
        }
        MonRow { label: "ram";  pct: SysMon.memPct;  barColor: Theme.blue; detail: SysMon.memUsedG.toFixed(1) + "G / " + SysMon.memTotalG.toFixed(1) + "G" }
        MonRow { label: "disk"; pct: SysMon.diskPct; barColor: Theme.purple; detail: SysMon.diskUsed + " / " + SysMon.diskAvail }
        MonRow {
            visible: SysMon.gpuPct >= 0
            label: "gpu"; pct: SysMon.gpuPct; barColor: Theme.orange
            detail: SysMon.gpuMemTotal > 0
                    ? SysMon.gpuMemUsed.toFixed(1) + "G / " + SysMon.gpuMemTotal.toFixed(1) + "G"
                    : ""
        }
        InfoPair { label: "net down"; value: SysMon.fmtRate(SysMon.netRx) }
        InfoPair { label: "net up";   value: SysMon.fmtRate(SysMon.netTx) }
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
