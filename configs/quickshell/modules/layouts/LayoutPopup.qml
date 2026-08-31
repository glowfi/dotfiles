import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Services"
import "../../Widgets"

PopupWindow {
    required property var bar
    id: layoutPopup
    anchor.window: bar
    anchor.rect.x: 90
    anchor.rect.y: Theme.barHeight
    implicitWidth: 270
    implicitHeight: layoutCol.implicitHeight + 16
    visible: false
    color: Theme.bg0h

    ColumnLayout {
        id: layoutCol
        anchors.fill: parent
        anchors.margins: 8
        spacing: 2
        Repeater {
            model: Mango.mangoLayouts
            Rectangle {
                required property var modelData
                readonly property bool current: bar.mLayoutSym === modelData.sym
                Layout.fillWidth: true
                implicitHeight: 36
                radius: 5
                color: current ? Theme.bg2 : (loMa.containsMouse ? Theme.bg1 : "transparent")
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    Text {
                        text: modelData.sym
                        color: parent.parent.current ? Theme.yellow : Theme.green
                        font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
                        Layout.preferredWidth: 46
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData.name
                        color: Theme.fg
                        font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
                    }
                }
                MouseArea {
                    id: loMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        Mango.dispatch("setlayout," + modelData.name);
                        layoutPopup.visible = false;
                    }
                }
            }
        }
    }
}
