import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../../Services"
import "../../Widgets"

PanelWindow {
    id: gpuPopup
    required property var bar
    screen: bar.screen
    anchors { top: true; left: true }
    margins { top: Theme.barHeight + 4; left: 8 }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    implicitWidth: 360
    implicitHeight: gpuCol.implicitHeight + 28
    visible: false
    color: Theme.bg0h

    ColumnLayout {
        id: gpuCol
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        spacing: 8

        SectionLabel { text: "GPU" + (Gpu.gpus.length > 1 ? "S  (click name to monitor)" : "") }

        Repeater {
            model: Gpu.gpus
            ColumnLayout {
                id: gpuEntry
                required property var modelData
                required property int index
                readonly property bool current: Gpu.selected === index
                Layout.fillWidth: true
                spacing: 4

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: 5
                    color: gpuEntry.current ? Theme.bg2 : (gMa.containsMouse ? Theme.bg1 : "transparent")
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        Text {
                            Layout.fillWidth: true
                            text: gpuEntry.modelData.name
                            color: gpuEntry.current ? Theme.fg0 : Theme.fg
                            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
                        }
                        Text {
                            visible: gpuEntry.current
                            text: "󰄬"
                            color: Theme.green
                            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
                        }
                    }
                    MouseArea {
                        id: gMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Gpu.selected = gpuEntry.index
                    }
                }
                MonRow {
                    label: "busy"
                    pct: Math.max(0, gpuEntry.modelData.busy)
                    barColor: Theme.orange
                    detail: gpuEntry.modelData.busy < 0 ? "n/a" : ""
                }
                MonRow {
                    visible: gpuEntry.modelData.vramTotal > 0
                    label: "vram"
                    pct: gpuEntry.modelData.vramTotal > 0
                         ? 100 * gpuEntry.modelData.vramUsed / gpuEntry.modelData.vramTotal : 0
                    barColor: Theme.purple
                    detail: Gpu.fmtG(gpuEntry.modelData.vramUsed) + " / "
                            + Gpu.fmtG(gpuEntry.modelData.vramTotal)
                }
            }
        }

        // per-app render offload helper (only meaningful with 2+ GPUs)
        SectionLabel { text: "RUN AN APP ON THE OTHER GPU"; visible: Gpu.gpus.length > 1 }
        RowLayout {
            visible: Gpu.gpus.length > 1
            Layout.fillWidth: true
            spacing: 8
            Text {
                Layout.fillWidth: true
                text: "DRI_PRIME=1 <app>"
                color: Theme.fgDim
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 2 }
            }
            ActionChip {
                label: "copy"
                onClicked: Quickshell.execDetached(["sh", "-c", "printf 'DRI_PRIME=1 ' | wl-copy"])
            }
        }
    }
}
