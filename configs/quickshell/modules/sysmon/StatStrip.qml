import QtQuick
import QtQuick.Layouts
import "../../Services"
import "../../Widgets"

// The original SysChip visuals, display-only: no popup, no click, no btop.
Rectangle {
    id: statStrip
    implicitWidth: chipRow.implicitWidth + 20
    implicitHeight: 30
    radius: 4
    color: "transparent"

    RowLayout {
        id: chipRow
        anchors.centerIn: parent
        spacing: 12

        ChipStat {
            tooltip: "cpu usage · clock"
            icon: "󰻠"
            value: Math.round(SysMon.cpuPct) + "%"
                   + (SysMon.cpuMhz > 0 ? " " + (SysMon.cpuMhz / 1000).toFixed(1) + "GHz" : "")
        }
        ChipStat { tooltip: "memory used / total"; icon: "󰍛"; value: SysMon.memUsedG.toFixed(1) + "/" + SysMon.memTotalG.toFixed(0) + "G" }
        ChipStat { tooltip: "disk used / free"; icon: "󰋊"; value: SysMon.diskUsed + "/" + SysMon.diskAvail }
        ChipStat { tooltip: "net download"; icon: "󰇚"; value: SysMon.fmtRateShort(SysMon.netRx) }
        ChipStat { tooltip: "net upload"; icon: "󰕒"; value: SysMon.fmtRateShort(SysMon.netTx) }
    }
}
