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
                    ToolTip {
                        visible: thumbMa.containsMouse
                        delay: 700
                        padding: 8
                        background: Rectangle {
                            color: Theme.bg0h
                            radius: 6
                            border.width: 1
                            border.color: Theme.bg2
                        }
                        contentItem: Text {
                            text: modelData.split("/").pop()
                            color: Theme.fg
                            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 3 }
                        }
                    }
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
