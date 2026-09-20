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

    // subsequence fuzzy match (same as clipboard search)
    function fuzzy(hay, q) {
        hay = hay.toLowerCase(); q = q.toLowerCase();
        let i = 0;
        for (const c of q) { i = hay.indexOf(c, i); if (i < 0) return false; i++; }
        return true;
    }
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

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 30
            radius: 5
            color: Theme.bg1
            border.width: 1
            border.color: wifiSearch.activeFocus ? Theme.yellow : Theme.bg2
            visible: Net.wifiEnabled
            TextInput {
                id: wifiSearch
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.fg
                clip: true
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
                Keys.onEscapePressed: { if (text !== "") text = ""; else wifiPopup.visible = false }
            }
            Text {
                anchors.fill: wifiSearch
                verticalAlignment: Text.AlignVCenter
                visible: wifiSearch.text === "" && !wifiSearch.activeFocus
                text: "search networks…"
                color: Theme.gray
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
            }
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
                    model: Net.wifiEnabled
                           ? Net.wifiNets.filter(n => wifiSearch.text === ""
                                                 || wifiPopup.fuzzy(n.ssid, wifiSearch.text))
                           : []
                    ColumnLayout {
                        id: netEntry
                        required property var modelData
                        readonly property bool saved: Net.isSaved(modelData.ssid)
                        readonly property bool busy: Net.wifiBusySsid === modelData.ssid
                        Layout.fillWidth: true
                        spacing: 4

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 46
                            radius: 5
                            color: netEntry.modelData.inUse ? Theme.bg2
                                 : netEntry.busy ? Theme.bg1
                                 : (wnMa.containsMouse ? Theme.bg1 : "transparent")
                            border.width: netEntry.busy ? 1 : 0
                            border.color: Theme.yellow
                            Behavior on color { ColorAnimation { duration: 120 } }
                            scale: wnMa.pressed ? 0.98 : 1
                            Behavior on scale { NumberAnimation { duration: 80 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8
                                Text {
                                    text: Theme.wifiIcon(netEntry.modelData.signal)
                                    color: netEntry.modelData.inUse ? Theme.green : Theme.fg
                                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize + 5 }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    Text {
                                        Layout.fillWidth: true
                                        text: netEntry.modelData.ssid
                                        color: netEntry.modelData.inUse ? Theme.green : Theme.fg
                                        elide: Text.ElideRight
                                        font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: {
                                            if (netEntry.busy) return "connecting…";
                                            if (netEntry.modelData.inUse) return "connected — click to disconnect · right-click: forget";
                                            if (netEntry.saved) return "saved — click to connect · right-click: forget";
                                            if (netEntry.modelData.security !== "") return "secured — click to enter password";
                                            return "open — click to connect";
                                        }
                                        color: netEntry.busy ? Theme.yellow : Theme.gray
                                        elide: Text.ElideRight
                                        font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 4 }
                                    }
                                }
                                Text {
                                    visible: netEntry.modelData.inUse
                                    text: "󰄬"
                                    color: Theme.green
                                    Layout.preferredWidth: 22
                                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
                                }
                                Text {
                                    visible: netEntry.modelData.security !== ""
                                    text: "󰌾"
                                    color: netEntry.saved ? Theme.fgDim : Theme.gray
                                    Layout.preferredWidth: 20
                                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
                                }
                            }
                            MouseArea {
                                id: wnMa
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: ev => {
                                    const d = netEntry.modelData;
                                    if (ev.button === Qt.RightButton) {
                                        if (netEntry.saved || d.inUse) Net.forgetWifi(d.ssid);
                                        return;
                                    }
                                    if (netEntry.busy) return;
                                    if (d.inUse) { Net.disconnectWifi(d.ssid); return; }
                                    if (d.security !== "" && !netEntry.saved) {
                                        // secured + unknown: ask for the password FIRST —
                                        // the current connection is untouched until "join"
                                        Net.wifiPwSsid = d.ssid;
                                        return;
                                    }
                                    Net.connectWifi(d.ssid, "");
                                }
                            }
                        }
                        RowLayout {
                            visible: Net.wifiPwSsid === netEntry.modelData.ssid
                            Layout.fillWidth: true
                            spacing: 6
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 32
                                radius: 5
                                color: Theme.bg1
                                border.width: 1
                                border.color: pwInput.activeFocus ? Theme.yellow : Theme.bg2
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
                                    onAccepted: Net.connectWifi(netEntry.modelData.ssid, text)
                                    onVisibleChanged: if (visible) forceActiveFocus()
                                }
                            }
                            ActionChip {
                                label: netEntry.busy ? "joining…" : "join"
                                accent: true
                                enabled: !netEntry.busy
                                onClicked: Net.connectWifi(netEntry.modelData.ssid, pwInput.text)
                            }
                            ActionChip {
                                label: "󰅖"
                                onClicked: Net.wifiPwSsid = ""
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
