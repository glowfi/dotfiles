import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../Services"
import "../../Widgets"

PopupWindow {
    required property var bar
    id: clipPopup
    anchor.window: bar
    anchor.rect.x: bar.width - 490
    anchor.rect.y: Theme.barHeight
    implicitWidth: 480
    implicitHeight: 460
    visible: false
    color: Theme.bg0h

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6
        Text {
            text: "Clipboard history  (click to copy)"
            color: Theme.purple
            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
        }
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            ScrollBar.vertical: GruvScrollBar {}
            model: Clip.clipEntries
            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width
                height: 38
                radius: 5
                color: clMa.containsMouse ? Theme.bg1 : "transparent"
                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    text: modelData.preview
                    color: Theme.fg
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
                }
                MouseArea {
                    id: clMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        Clip.copyClip(modelData.cid);
                        clipPopup.visible = false;
                    }
                }
            }
            Text {
                anchors.centerIn: parent
                visible: Clip.clipEntries.length === 0
                text: "empty — is `wl-paste --watch cliphist store` running?"
                color: Theme.gray
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
            }
        }
    }
}
