import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../Services"
import "../../Widgets"

PopupWindow {
    required property var bar
    id: notifPopup
    anchor.window: bar
    anchor.rect.x: bar.width - 440
    anchor.rect.y: Theme.barHeight
    implicitWidth: 430
    implicitHeight: 520
    visible: false
    color: Theme.bg0h

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: "Notifications"
                color: Theme.yellow
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
            }
            Text {
                text: "dnd"
                color: NotifSvc.doNotDisturb ? Theme.red : Theme.fgDim
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 3 }
            }
            TogglePill {
                on: NotifSvc.doNotDisturb
                onClicked: NotifSvc.doNotDisturb = !NotifSvc.doNotDisturb
            }
            Rectangle {
                implicitWidth: 100; implicitHeight: 30; radius: 5
                color: caMa.containsMouse ? Theme.bg2 : Theme.bg1
                Text {
                    anchors.centerIn: parent
                    text: "clear all"
                    color: Theme.fgDim
                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 2 }
                }
                MouseArea {
                    id: caMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: NotifSvc.notifHistory.clear()
                }
            }
        }
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            ScrollBar.vertical: GruvScrollBar {}
            model: NotifSvc.notifHistory
            delegate: Rectangle {
                required property var model
                width: ListView.view.width
                height: nhCol.implicitHeight + 16
                radius: 6
                color: Theme.bg1
                ColumnLayout {
                    id: nhCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                    spacing: 2
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: model.nApp + (model.nSummary ? "  ·  " + model.nSummary : "")
                            color: Theme.fg
                            elide: Text.ElideRight
                            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
                        }
                        Text {
                            text: model.nTime
                            color: Theme.gray
                            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 3 }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: model.nBody !== ""
                        text: model.nBody
                        color: Theme.fgDim
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 2 }
                    }
                }
            }
            Text {
                anchors.centerIn: parent
                visible: NotifSvc.notifHistory.count === 0
                text: "all caught up"
                color: Theme.gray
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
            }
        }
    }
}
