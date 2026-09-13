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
    onVisibleChanged: if (visible) BtCtl.refreshKnown()
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
                label: BtCtl.scanning || (a && a.discovering) ? "scanning…" : "󰑐 scan"
                enabled: a !== null && a.enabled && !BtCtl.scanning
                onClicked: {
                    BtCtl.scan();                                // reliable CLI path
                    try { a.discovering = true; } catch (e) {}   // best-effort native
                }
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
                                .sort((x, y) => (y.connected - x.connected) || ((y.paired || (y.bonded ?? false)) - (x.paired || (x.bonded ?? false))));
                        }
                    }
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 40
                        radius: 5
                        color: BtCtl.busyAddr === modelData.address && !modelData.connected
                               ? Theme.bg1
                               : (bdMa.containsMouse ? Theme.bg1 : "transparent")
                        border.width: BtCtl.busyAddr === modelData.address && !modelData.connected ? 1 : 0
                        border.color: Theme.yellow
                        Behavior on color { ColorAnimation { duration: 120 } }
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
                                    text: {
                                        if (BtCtl.busyAddr === modelData.address && !modelData.connected)
                                            return BtCtl.busyAction;
                                        if (modelData.connected)
                                            return "connected — click to disconnect · right-click: forget";
                                        if (modelData.paired || (modelData.bonded ?? false)
                                            || BtCtl.isKnown(modelData.address))
                                            return "paired — click to connect · right-click: forget";
                                        return "not paired — click to pair";
                                    }
                                    color: BtCtl.busyAddr === modelData.address && !modelData.connected
                                           ? Theme.yellow : Theme.gray
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
                        onVisibleChanged: {}   // (row-level)
                        Connections {
                            target: modelData
                            function onConnectedChanged() {
                                if (modelData.connected && BtCtl.busyAddr === modelData.address)
                                    BtCtl.clearBusy();
                            }
                        }
                        MouseArea {
                            id: bdMa
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: ev => {
                                if (ev.button === Qt.RightButton) {
                                    // forget, wifi-popup-consistent
                                    if (modelData.paired || (modelData.bonded ?? false)
                                        || BtCtl.isKnown(modelData.address)) {
                                        try { modelData.forget(); } catch (e) {}
                                        BtCtl.refreshKnown();
                                        BtCtl.scan();   // so it can reappear for re-pairing
                                    }
                                    return;
                                }
                                if (BtCtl.busyAddr === modelData.address && modelData.connected)
                                    BtCtl.clearBusy();
                                const known = modelData.paired || (modelData.bonded ?? false) || BtCtl.isKnown(modelData.address);
                                if (modelData.connected) modelData.disconnect();
                                else if (known) BtCtl.connectDevice(modelData.address);
                                else BtCtl.pairDevice(modelData.address);   // pair + trust + connect
                            }
                        }
                    }
                }
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    visible: BtCtl.scanning
                    text: "scanning — put the device in pairing mode to (re)discover it"
                    color: Theme.gray
                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 4 }
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
