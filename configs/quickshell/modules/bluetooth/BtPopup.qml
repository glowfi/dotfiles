import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../Services"
import "../../Widgets"
import Quickshell.Wayland
import Quickshell.Bluetooth

PanelWindow {
    required property var bar
    id: btPopup
    screen: bar.screen
    anchors { top: true; left: true }
    margins { top: Theme.barHeight + 4; left: 8 }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    implicitWidth: 340
    implicitHeight: Math.min(460, btHead.implicitHeight + btFlick.contentHeight + 44)
    visible: false
    color: "transparent"

    // popup surface: rounded + hairline border (windows are transparent)
    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Theme.bg0h
        border.width: 1
        border.color: Theme.bg2
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        RowLayout {
            id: btHead
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: "Bluetooth"
                color: Theme.yellow
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
            }
            TogglePill {
                on: Bluetooth.defaultAdapter !== null && Bluetooth.defaultAdapter.enabled
                onClicked: {
                    const a = Bluetooth.defaultAdapter;
                    if (a) a.enabled = !a.enabled;
                }
            }
            ActionChip {
                readonly property var a: Bluetooth.defaultAdapter
                label: a && a.discovering ? "scanning…" : "󰑐 scan"
                enabled: a !== null && a.enabled
                onClicked: { try { a.discovering = !a.discovering; } catch (e) {} }
            }
        }

        Flickable {
            id: btFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            flickableDirection: Flickable.VerticalFlick
            contentHeight: btCol.implicitHeight
            clip: true
            ScrollBar.vertical: GruvScrollBar {}
            ColumnLayout {
                id: btCol
                width: btFlick.width - 14   // scrollbar gutter, measured off the Flickable
                spacing: 4
                Repeater {
                    model: ScriptModel {
                        values: {
                            const a = Bluetooth.defaultAdapter;
                            if (!a || !a.enabled) return [];
                            return [...a.devices.values]
                                .filter(d => d.paired || d.connected || (d.name ?? "") !== "")
                                .sort((x, y) => (y.connected - x.connected) || (y.paired - x.paired));
                        }
                    }
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 40
                        radius: 5
                        color: bdMa.containsMouse ? Theme.bg1 : "transparent"
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8
                            Text {
                                text: modelData.connected ? "󰂱" : "󰂯"
                                color: modelData.connected ? Theme.blue : Theme.fgDim
                                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize + 4 }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name || modelData.address || "?"
                                    color: modelData.connected ? Theme.blue : Theme.fg
                                    elide: Text.ElideRight
                                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
                                }
                                Text {
                                    text: modelData.connected ? "connected — click to disconnect"
                                        : (modelData.paired ? "paired — click to connect" : "click to connect")
                                    color: Theme.gray
                                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 4 }
                                }
                            }
                            Text {
                                visible: (modelData.batteryAvailable ?? false)
                                text: Math.round((modelData.battery ?? 0) * 100) + "%"
                                color: Theme.fgDim
                                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 2 }
                            }
                        }
                        MouseArea {
                            id: bdMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (modelData.connected) modelData.disconnect();
                                else modelData.connect();
                            }
                        }
                    }
                }
                Text {
                    visible: Bluetooth.defaultAdapter === null || !Bluetooth.defaultAdapter.enabled
                    text: "bluetooth is off"
                    color: Theme.gray
                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
                }
            }
        }
    }
}
