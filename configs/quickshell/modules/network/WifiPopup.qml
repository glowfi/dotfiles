import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../Services"
import "../../Widgets"
import Quickshell.Wayland

PanelWindow {
    required property var bar
    id: wifiPopup
    screen: bar.screen
    anchors { top: true; left: true }
    margins { top: Theme.barHeight + 4; left: 8 }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    implicitWidth: 390
    implicitHeight: 440
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
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: "Wi-Fi"
                color: Theme.yellow
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
            }
            TogglePill {
                on: Net.wifiEnabled
                onClicked: Net.toggleWifi()
            }
            ActionChip {
                label: Net.wifiScanning ? "scanning…" : "󰑐 rescan"
                enabled: Net.wifiEnabled && !Net.wifiScanning
                onClicked: Net.scanWifi()
            }
        }

        Text {
            visible: Net.wifiError !== ""
            Layout.fillWidth: true
            text: Net.wifiError
            color: Theme.red
            wrapMode: Text.Wrap
            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 2 }
        }

        Flickable {
            id: wifiFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: wifiCol.implicitHeight
            flickableDirection: Flickable.VerticalFlick
            clip: true
            ScrollBar.vertical: GruvScrollBar {}
            ColumnLayout {
                id: wifiCol
                width: wifiFlick.width - 14   // scrollbar gutter, measured off the Flickable
                spacing: 4
                Repeater {
                    model: Net.wifiEnabled ? Net.wifiNets : []
                    ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 4
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 38
                            radius: 5
                            color: modelData.inUse ? Theme.bg2 : (wnMa.containsMouse ? Theme.bg1 : "transparent")
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 6
                                Text {
                                    text: Theme.wifiIcon(modelData.signal)
                                    color: modelData.inUse ? Theme.green : Theme.fg
                                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize + 5 }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.ssid + (modelData.inUse ? "   (connected)" : "")
                                    color: modelData.inUse ? Theme.green : Theme.fg
                                    elide: Text.ElideRight
                                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
                                }
                                Text {
                                    visible: modelData.security !== ""
                                    text: "󰌾"
                                    color: Theme.gray
                                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 2 }
                                }
                            }
                            MouseArea {
                                id: wnMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (modelData.inUse) return;
                                    Net.wifiPwSsid = "";
                                    Net.connectWifi(modelData.ssid, "");
                                }
                            }
                        }
                        RowLayout {
                            visible: Net.wifiPwSsid === modelData.ssid
                            Layout.fillWidth: true
                            spacing: 6
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 32
                                radius: 5
                                color: Theme.bg1
                                border.width: 1
                                border.color: Theme.yellow
                                TextInput {
                                    id: pwInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    verticalAlignment: TextInput.AlignVCenter
                                    echoMode: TextInput.Password
                                    color: Theme.fg
                                    clip: true
                                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
                                    onAccepted: Net.connectWifi(modelData.ssid, text)
                                }
                            }
                            ActionChip {
                                label: "join"
                                accent: true
                                onClicked: Net.connectWifi(modelData.ssid, pwInput.text)
                            }
                        }
                    }
                }
                Text {
                    visible: !Net.wifiEnabled
                    text: "wifi is off"
                    color: Theme.gray
                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
                }
            }
        }
    }
}
