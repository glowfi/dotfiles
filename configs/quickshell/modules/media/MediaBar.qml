import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../Services"
import "../../Widgets"

Rectangle {
    visible: MediaSvc.hasMedia
    implicitWidth: mediaRow.implicitWidth + 16
    implicitHeight: 30
    radius: 4
    color: "transparent"
    RowLayout {
        id: mediaRow
        anchors.centerIn: parent
        spacing: 8
        Text {
            text: "󰒮"
            color: MediaSvc.activePlayer && MediaSvc.activePlayer.canGoPrevious ? Theme.fg : Theme.bg3
            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize + 2 }
            MouseArea {
                anchors.fill: parent
                onClicked: if (MediaSvc.activePlayer && MediaSvc.activePlayer.canGoPrevious)
                               MediaSvc.activePlayer.previous()
            }
        }
        Text {
            text: MediaSvc.activePlayer && MediaSvc.activePlayer.isPlaying ? "󰏤" : "󰐊"
            color: Theme.green
            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize + 4 }
            MouseArea {
                anchors.fill: parent
                onClicked: if (MediaSvc.activePlayer && MediaSvc.activePlayer.canTogglePlaying)
                               MediaSvc.activePlayer.togglePlaying()
            }
        }
        Text {
            text: "󰒭"
            color: MediaSvc.activePlayer && MediaSvc.activePlayer.canGoNext ? Theme.fg : Theme.bg3
            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize + 2 }
            MouseArea {
                anchors.fill: parent
                onClicked: if (MediaSvc.activePlayer && MediaSvc.activePlayer.canGoNext)
                               MediaSvc.activePlayer.next()
            }
        }
        Text {
            text: {
                const t = MediaSvc.activePlayer ? (MediaSvc.activePlayer.trackTitle ?? "") : "";
                const a = MediaSvc.activePlayer ? (MediaSvc.activePlayer.trackArtist ?? "") : "";
                return a !== "" ? t + " — " + a : t;
            }
            color: MediaSvc.activePlayer && MediaSvc.activePlayer.isPlaying ? Theme.fg : Theme.fgDim
            elide: Text.ElideRight
            Layout.maximumWidth: 240
            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
        }
    }
}
