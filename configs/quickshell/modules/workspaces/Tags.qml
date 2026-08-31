import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Services"
import "../../Widgets"

RowLayout {
    required property var bar
    spacing: 3
    Repeater {
        model: bar.mTags
        Rectangle {
            required property var modelData
            readonly property bool on: modelData.is_active === true
            readonly property bool occupied: (modelData.client_count ?? 0) > 0
            width: 34; height: 28; radius: 5
            color: on ? Theme.yellow : (tagMa.containsMouse ? Theme.bg2 : Theme.bg1)
            border.width: modelData.is_urgent === true ? 1 : 0
            border.color: Theme.red
            opacity: (on || occupied) ? 1.0 : 0.45
            Text {
                anchors.centerIn: parent
                text: modelData.index
                color: parent.on ? Theme.bg0 : Theme.fg
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
            }
            Rectangle {
                visible: parent.occupied && !parent.on
                width: 5; height: 5; radius: 2.5
                color: Theme.orange
                anchors { top: parent.top; right: parent.right; margins: 2 }
            }
            MouseArea {
                id: tagMa
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Mango.dispatch("view," + modelData.index)
            }
        }
    }
}
