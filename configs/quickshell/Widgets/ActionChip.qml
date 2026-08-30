import QtQuick
import "../Services"

Rectangle {
    property string label
    property bool accent: false
    signal clicked()
    opacity: enabled ? 1 : 0.45
    implicitWidth: chipText.width + 20
    implicitHeight: 30
    radius: 5
    color: accent ? Theme.yellow : (acMa.containsMouse && enabled ? Theme.bg2 : Theme.bg1)
    Text {
        id: chipText
        anchors.centerIn: parent
        text: parent.label
        color: parent.accent ? Theme.bg0 : Theme.fg
        font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 2 }
    }
    MouseArea {
        id: acMa
        anchors.fill: parent
        hoverEnabled: true
        enabled: parent.enabled
        onClicked: parent.clicked()
    }
}
