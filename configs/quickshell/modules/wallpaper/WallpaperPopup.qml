// Wallpaper popup: 3-column thumbnail grid (the slat strip lives in
// WallPicker.qml, the fullscreen overlay on meta+w).
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../../Services"
import "../../Widgets"

PanelWindow {
    id: wallpaperPopup
    required property var bar
    screen: bar.screen
    anchors { top: true; left: true }
    margins { top: Theme.barHeight + 4; left: 8 }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    implicitWidth: 460
    implicitHeight: wallCol.implicitHeight + 28
    visible: false
    color: "transparent"
    onVisibleChanged: if (visible) Wallpaper.rescan()

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Theme.bg0h
        border.width: 1
        border.color: Theme.bg2
    }

    ColumnLayout {
        id: wallCol
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            SectionLabel { Layout.fillWidth: true; text: "WALLPAPER" }
            ActionChip { label: "󰑐 rescan"; onClicked: Wallpaper.rescan() }
        }

        Flickable {
            id: wallFlick
            Layout.fillWidth: true
            implicitHeight: Math.min(420, wallGrid.implicitHeight)
            contentWidth: width
            contentHeight: wallGrid.implicitHeight
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            ScrollBar.vertical: GruvScrollBar {}

            GridLayout {
                id: wallGrid
                width: wallFlick.width - 14   // scrollbar gutter
                columns: 3
                rowSpacing: 8
                columnSpacing: 8
                Repeater {
                model: Wallpaper.walls
                Rectangle {
                    id: thumb
                    required property string modelData
                    property bool _tipUp: false
                    Layout.fillWidth: true
                    implicitHeight: 110
                    radius: 6
                    clip: true
                    color: Theme.bg1
                    border.width: thumbMa.containsMouse ? 2 : 0
                    border.color: Theme.yellow

                    Image {
                        anchors.fill: parent
                        anchors.margins: thumb.border.width
                        asynchronous: true
                        sourceSize.width: 380
                        fillMode: Image.PreserveAspectCrop
                        source: "file://" + thumb.modelData
                    }
                    Timer {
                        interval: 700
                        running: thumbMa.containsMouse
                        onTriggered: thumb._tipUp = true
                    }
                    Rectangle {
                        visible: thumb._tipUp && thumbMa.containsMouse
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 4
                        z: 99
                        implicitWidth: Math.min(wpTipText.implicitWidth + 16, parent.width)
                        implicitHeight: 24
                        radius: 6
                        color: Theme.bg0h
                        border.width: 1
                        border.color: Theme.bg2
                        Text {
                            id: wpTipText
                            anchors.centerIn: parent
                            width: Math.min(implicitWidth, parent.width - 12)
                            elide: Text.ElideMiddle
                            text: thumb.modelData.split("/").pop()
                            color: Theme.fg
                            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 4 }
                        }
                    }
                    MouseArea {
                        id: thumbMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onContainsMouseChanged: if (!containsMouse) thumb._tipUp = false
                        onClicked: Wallpaper.set(thumb.modelData)
                    }
                    }
                }
            }
        }

        Text {
            visible: Wallpaper.walls.length === 0
            text: "no wallpapers found in " + Wallpaper.wallDir
            color: Theme.gray
            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 2 }
        }
    }
}
