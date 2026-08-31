import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Services"
import "../../Widgets"
import Quickshell.Wayland
import Quickshell.Services.Pipewire

PanelWindow {
    required property var bar
    id: audioPopup
    screen: bar.screen
    anchors { top: true; left: true }
    margins { top: Theme.barHeight + 4; left: 8 }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    implicitWidth: 340
    implicitHeight: audioCol.implicitHeight + 28
    visible: false
    color: Theme.bg0h

    ColumnLayout {
        id: audioCol
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        spacing: 10

        SectionLabel { text: "OUTPUT" }
        RowLayout {
            spacing: 8
            readonly property var sink: Pipewire.defaultAudioSink
            PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
            Text {
                text: parent.sink && parent.sink.audio
                      ? Theme.volIcon(parent.sink.audio.volume, parent.sink.audio.muted) : "󰕿"
                color: parent.sink && parent.sink.audio && parent.sink.audio.muted ? Theme.gray : Theme.fg0
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.iconSize }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        const a = Pipewire.defaultAudioSink;
                        if (a && a.audio) a.audio.muted = !a.audio.muted;
                    }
                }
            }
            GruvSlider {
                Layout.fillWidth: true
                value: (parent.sink && parent.sink.audio) ? parent.sink.audio.volume : 0
                onMoved: v => {
                    const a = Pipewire.defaultAudioSink;
                    if (a && a.audio) a.audio.volume = v;
                }
            }
            Text {
                text: (parent.sink && parent.sink.audio)
                      ? Math.round(parent.sink.audio.volume * 100) + "%" : "--"
                color: Theme.fgDim
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
                Layout.preferredWidth: 52
            }
        }

        // output device picker
        Repeater {
            model: ScriptModel {
                values: (Pipewire.nodes ? [...Pipewire.nodes.values] : [])
                    .filter(n => n && n.isSink && !n.isStream && (n.description ?? n.name ?? "") !== "")
            }
            Rectangle {
                required property var modelData
                readonly property bool current: modelData === Pipewire.defaultAudioSink
                Layout.fillWidth: true
                implicitHeight: 34
                radius: 5
                color: current ? Theme.bg2 : (devMa.containsMouse ? Theme.bg1 : "transparent")
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6
                    Text {
                        text: parent.parent.current ? "󰄬" : "󰓃"
                        color: parent.parent.current ? Theme.green : Theme.fgDim
                        font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData.description ?? modelData.name
                        color: parent.parent.current ? Theme.fg0 : Theme.fg
                        elide: Text.ElideRight
                        font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 2 }
                    }
                }
                MouseArea {
                    id: devMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Quickshell.execDetached(["wpctl", "set-default", String(modelData.id)])
                }
            }
        }

        SectionLabel { text: "INPUT" }
        RowLayout {
            spacing: 8
            readonly property var src: Pipewire.defaultAudioSource
            PwObjectTracker { objects: [Pipewire.defaultAudioSource] }
            visible: src !== null
            Text {
                text: parent.src && parent.src.audio && parent.src.audio.muted ? "󰍭" : "󰍬"
                color: parent.src && parent.src.audio && parent.src.audio.muted ? Theme.gray : Theme.fg0
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.iconSize }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        const a = Pipewire.defaultAudioSource;
                        if (a && a.audio) a.audio.muted = !a.audio.muted;
                    }
                }
            }
            GruvSlider {
                Layout.fillWidth: true
                value: (parent.src && parent.src.audio) ? parent.src.audio.volume : 0
                onMoved: v => {
                    const a = Pipewire.defaultAudioSource;
                    if (a && a.audio) a.audio.volume = v;
                }
            }
            Text {
                text: (parent.src && parent.src.audio)
                      ? Math.round(parent.src.audio.volume * 100) + "%" : "--"
                color: Theme.fgDim
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
                Layout.preferredWidth: 52
            }
        }

        // input device picker (mics, line-in, headset mics)
        Repeater {
            model: ScriptModel {
                values: (Pipewire.nodes ? [...Pipewire.nodes.values] : [])
                    .filter(n => n && n.isSink === false && !n.isStream
                                 && n.audio && (n.description ?? n.name ?? "") !== "")
            }
            Rectangle {
                required property var modelData
                readonly property bool current: modelData === Pipewire.defaultAudioSource
                Layout.fillWidth: true
                implicitHeight: 34
                radius: 5
                color: current ? Theme.bg2 : (inDevMa.containsMouse ? Theme.bg1 : "transparent")
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6
                    Text {
                        text: parent.parent.current ? "󰄬" : "󰍬"
                        color: parent.parent.current ? Theme.green : Theme.fgDim
                        font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData.description ?? modelData.name
                        color: parent.parent.current ? Theme.fg0 : Theme.fg
                        elide: Text.ElideRight
                        font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 2 }
                    }
                }
                MouseArea {
                    id: inDevMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Quickshell.execDetached(["wpctl", "set-default", String(modelData.id)])
                }
            }
        }
    }
}