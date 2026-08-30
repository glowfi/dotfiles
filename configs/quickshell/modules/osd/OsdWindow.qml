import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "../../Services"
import "../../Widgets"

PanelWindow {
        visible: OsdSvc.osdShown
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        anchors { bottom: true }
        margins { bottom: 140 }
        implicitWidth: 340
        implicitHeight: 74
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: Theme.bg0h
            border.width: 1
            border.color: Theme.bg2

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                spacing: 14

                readonly property var sink: Pipewire.defaultAudioSink
                readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
                readonly property real frac: OsdSvc.osdKind === "volume"
                    ? (sink && sink.audio ? Math.min(1, sink.audio.volume) : 0)
                    : Math.max(0, DisplayCtl.brightness) / 100

                Text {
                    text: OsdSvc.osdKind === "brightness" ? "󰃞"
                        : parent.muted ? "󰖁" : "󰕾"
                    color: (OsdSvc.osdKind === "volume" && parent.muted) ? Theme.gray : Theme.yellow
                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.iconSize + 2 }
                }
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 8
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width; height: 8; radius: 4
                        color: Theme.bg2
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.parent.frac * parent.width
                        height: 8; radius: 4
                        color: (OsdSvc.osdKind === "volume" && parent.parent.muted) ? Theme.gray : Theme.yellow
                    }
                }
                Text {
                    text: (OsdSvc.osdKind === "volume" && parent.muted) ? "mute"
                        : Math.round(parent.frac * 100) + "%"
                    color: Theme.fg
                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
                    Layout.preferredWidth: 62
                }
            }
        }
    }
