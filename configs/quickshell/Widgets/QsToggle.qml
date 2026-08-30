import QtQuick
import QtQuick.Layouts
import "../Services"

Rectangle {
    property string icon
    property string label
    property bool active: false
    signal toggled()
    Layout.fillWidth: true
    implicitHeight: 64
    radius: 8
    color: active ? Theme.bg2 : (qtMa.containsMouse ? Theme.bg1 : Theme.bg0)
    border.width: 1
    border.color: active ? Theme.yellow : Theme.bg2
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 1
        Text {
            text: parent.parent.icon
            color: parent.parent.active ? Theme.yellow : Theme.fgDim
            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.iconSize }
            Layout.alignment: Qt.AlignHCenter
        }
        Text {
            text: parent.parent.label
            color: parent.parent.active ? Theme.fg : Theme.gray
            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 3 }
            Layout.alignment: Qt.AlignHCenter
        }
    }
    MouseArea {
        id: qtMa
        anchors.fill: parent
        hoverEnabled: true
        onClicked: parent.toggled()
    }
}
