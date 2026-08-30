import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../Services"
import "../../Widgets"
import Quickshell.Wayland
import Quickshell.Services.UPower

PanelWindow {
    required property var bar
    id: batteryPopup
    screen: bar.screen
    anchors { top: true; left: true }
    margins { top: Theme.barHeight + 4; left: 8 }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    implicitWidth: 310
    implicitHeight: batCol.implicitHeight + 28
    visible: false
    color: Theme.bg0h

    ColumnLayout {
        id: batCol
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        spacing: 8
        readonly property var dev: UPower.displayDevice

        SectionLabel { text: "BATTERY" }
        MonRow {
            label: "charge"
            pct: batCol.dev ? batCol.dev.percentage * 100 : 0
            barColor: batCol.dev && batCol.dev.state === UPowerDeviceState.Charging
                      ? Theme.aqua : (pct < 20 ? Theme.red : Theme.green)
        }
        InfoPair {
            label: "state"
            value: batCol.dev ? BatteryInfo.batStateText(batCol.dev.state) : "—"
        }
        InfoPair {
            label: batCol.dev && batCol.dev.state === UPowerDeviceState.Charging
                   ? "time to full" : "time left"
            value: {
                const d = batCol.dev;
                if (!d) return "—";
                return BatteryInfo.fmtSecs(d.state === UPowerDeviceState.Charging
                                    ? d.timeToFull : d.timeToEmpty);
            }
        }
        InfoPair {
            label: "power draw"
            value: batCol.dev && batCol.dev.changeRate > 0
                   ? batCol.dev.changeRate.toFixed(1) + " W" : "—"
        }
        InfoPair {
            label: "health"
            value: BatteryInfo.batHealth > 0 ? BatteryInfo.batHealth.toFixed(0) + "%" : "—"
        }
        InfoPair {
            label: "capacity"
            value: batCol.dev && batCol.dev.energyCapacity > 0
                   ? batCol.dev.energyCapacity.toFixed(1) + " Wh" : "—"
        }
        InfoPair {
            label: "charge cycles"
            value: BatteryInfo.batCycles > 0 ? String(BatteryInfo.batCycles) : "—"
        }

        SectionLabel { text: "POWER PROFILE" }
        Repeater {
            model: [
                { p: PowerProfile.PowerSaver,  icon: "󰾆", label: "power saver" },
                { p: PowerProfile.Balanced,    icon: "󰾅", label: "balanced" },
                { p: PowerProfile.Performance, icon: "󰓅", label: "performance" }
            ]
            Rectangle {
                required property var modelData
                readonly property bool current: PowerProfiles.profile === modelData.p
                visible: modelData.p !== PowerProfile.Performance
                         || PowerProfiles.hasPerformanceProfile
                Layout.fillWidth: true
                implicitHeight: 36
                radius: 5
                color: current ? Theme.bg2 : (ppMa.containsMouse ? Theme.bg1 : "transparent")
                border.width: current ? 1 : 0
                border.color: Theme.aqua
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8
                    Text {
                        text: modelData.icon
                        color: parent.parent.current ? Theme.aqua : Theme.fgDim
                        font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize + 2 }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData.label
                        color: parent.parent.current ? Theme.fg0 : Theme.fg
                        elide: Text.ElideRight
                        font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
                    }
                    Text {
                        visible: parent.parent.current
                        text: "󰄬"
                        color: Theme.green
                        font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
                    }
                }
                MouseArea {
                    id: ppMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: PowerProfiles.profile = modelData.p
                }
            }
        }
    }
}
