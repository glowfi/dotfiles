// In-shell wallpaper picker (quattro-style): thumbnail grid, click to apply
// with an animated transition via awww.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../Services"
import "../../Widgets"

PanelWindow {
    id: wallPopup
    required property var bar
    screen: bar.screen
    anchors { top: true; left: true }
    margins { top: Theme.barHeight + 4; left: 8 }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    implicitWidth: 480
    implicitHeight: 430
    visible: false
    color: Theme.bg0h

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: "Wallpapers"
                color: Theme.yellow
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
            }
            ActionChip {
                label: "󰑐 rescan"
                onClicked: Wallpaper.rescan()
            }
        }

        GridView {
            id: wallGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: Math.floor((width - 14) / 3)
            cellHeight: Math.floor(cellWidth * 0.62) + 8
            model: Wallpaper.walls
            ScrollBar.vertical: GruvScrollBar {}

            delegate: Item {
                required property var modelData
                width: wallGrid.cellWidth
                height: wallGrid.cellHeight
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: 6
                    color: Theme.bg1
                    clip: true
                    border.width: thumbMa.containsMouse ? 2 : 0
                    border.color: Theme.yellow
                    Image {
                        anchors.fill: parent
                        anchors.margins: thumbMa.containsMouse ? 2 : 0
                        source: "file://" + modelData
                        sourceSize.width: 300          // decode small: fast + sharp thumbs
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    MouseArea {
                        id: thumbMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            Wallpaper.set(modelData);
                            wallPopup.visible = false;
                        }
                    }
                    ToolTip.visible: thumbMa.containsMouse
                    ToolTip.text: modelData.split("/").pop()
                    ToolTip.delay: 700
                }
            }

            Text {
                anchors.centerIn: parent
                visible: Wallpaper.walls.length === 0
                width: parent.width - 40
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                text: "no images in " + Wallpaper.wallDir
                      + "\n(dir configurable in Services/Wallpaper.qml)"
                color: Theme.gray
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 2 }
            }
        }
    }
}
