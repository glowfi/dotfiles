import QtQuick
import QtQuick.Layouts
import "../Services"

RowLayout {
    property string label
    property real pct: 0        // 0..100
    property string detail: ""  // overrides the % text when set
    property color barColor: Theme.aqua
    spacing: 8
    Layout.fillWidth: true
    Text {
        text: parent.label
        color: Theme.fgDim
        font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 2 }
        Layout.preferredWidth: 56
    }
    Item {
        Layout.fillWidth: true
        implicitHeight: 10
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width; height: 8; radius: 4
            color: Theme.bg2
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, Math.min(100, parent.parent.pct)) / 100 * parent.width
            height: 8; radius: 4
            color: parent.parent.pct > 90 ? Theme.red : parent.parent.barColor
            Behavior on width { NumberAnimation { duration: 300 } }
        }
    }
    Text {
        text: parent.detail !== "" ? parent.detail : Math.round(parent.pct) + "%"
        color: Theme.fg
        font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 2 }
        Layout.preferredWidth: parent.detail !== "" ? 130 : 52
        horizontalAlignment: Text.AlignRight
    }
}
