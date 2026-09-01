// KDE-style media popup: cover art, track info, seek bar, transport controls.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../Services"
import "../../Widgets"

PanelWindow {
    id: mediaPopup
    required property var bar
    screen: bar.screen
    anchors { top: true; left: true }
    margins { top: Theme.barHeight + 4; left: 8 }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    implicitWidth: 400
    implicitHeight: mediaCol.implicitHeight + 28
    visible: false
    color: Theme.bg0h

    readonly property var player: MediaSvc.activePlayer

    // MPRIS position doesn't self-tick; poll it while the popup is open
    property real pos: 0
    Timer {
        interval: 500
        running: mediaPopup.visible && mediaPopup.player !== null
        repeat: true
        triggeredOnStart: true
        onTriggered: mediaPopup.pos = mediaPopup.player ? (mediaPopup.player.position ?? 0) : 0
    }

    function fmtTime(sec) {
        if (!sec || sec < 0) return "0:00";
        const m = Math.floor(sec / 60), s = Math.floor(sec % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    ColumnLayout {
        id: mediaCol
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        spacing: 12

        // ---- cover art + track info ----
        RowLayout {
            spacing: 12
            Rectangle {
                width: 96; height: 96
                radius: 8
                color: Theme.bg1
                clip: true
                Image {
                    anchors.fill: parent
                    source: mediaPopup.player ? (mediaPopup.player.trackArtUrl ?? "") : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }
                Text {   // placeholder when no art
                    anchors.centerIn: parent
                    visible: !mediaPopup.player
                             || (mediaPopup.player.trackArtUrl ?? "") === ""
                    text: "󰝚"
                    color: Theme.bg3
                    font { family: Theme.fontFamily; bold: true; pixelSize: 40 }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    Layout.fillWidth: true
                    text: mediaPopup.player ? (mediaPopup.player.trackTitle ?? "") : ""
                    color: Theme.fg0
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
                }
                Text {
                    Layout.fillWidth: true
                    text: mediaPopup.player ? (mediaPopup.player.trackArtist ?? "") : ""
                    color: Theme.fgDim
                    elide: Text.ElideRight
                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 2 }
                }
                Text {
                    text: mediaPopup.player ? (mediaPopup.player.identity ?? "") : ""
                    color: Theme.gray
                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 4 }
                }
            }
        }

        // ---- seek bar ----
        RowLayout {
            spacing: 8
            Text {
                text: mediaPopup.fmtTime(mediaPopup.pos)
                color: Theme.fgDim
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 3 }
            }
            GruvSlider {
                Layout.fillWidth: true
                opacity: mediaPopup.player && mediaPopup.player.canSeek ? 1 : 0.4
                value: {
                    const p = mediaPopup.player;
                    return (p && p.length > 0) ? mediaPopup.pos / p.length : 0;
                }
                onMoved: v => {
                    const p = mediaPopup.player;
                    if (p && p.canSeek && p.length > 0) {
                        p.position = v * p.length;
                        mediaPopup.pos = v * p.length;
                    }
                }
            }
            Text {
                text: mediaPopup.fmtTime(mediaPopup.player ? (mediaPopup.player.length ?? 0) : 0)
                color: Theme.fgDim
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 3 }
            }
        }

        // ---- transport ----
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 28
            Text {
                text: "󰒮"
                color: mediaPopup.player && mediaPopup.player.canGoPrevious ? Theme.fg : Theme.bg3
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.iconSize + 2 }
                MouseArea {
                    anchors.fill: parent
                    onClicked: if (mediaPopup.player && mediaPopup.player.canGoPrevious)
                                   mediaPopup.player.previous()
                }
            }
            Text {
                text: mediaPopup.player && mediaPopup.player.isPlaying ? "󰏤" : "󰐊"
                color: Theme.green
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.iconSize + 10 }
                MouseArea {
                    anchors.fill: parent
                    onClicked: if (mediaPopup.player && mediaPopup.player.canTogglePlaying)
                                   mediaPopup.player.togglePlaying()
                }
            }
            Text {
                text: "󰒭"
                color: mediaPopup.player && mediaPopup.player.canGoNext ? Theme.fg : Theme.bg3
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.iconSize + 2 }
                MouseArea {
                    anchors.fill: parent
                    onClicked: if (mediaPopup.player && mediaPopup.player.canGoNext)
                                   mediaPopup.player.next()
                }
            }
        }
    }
}
