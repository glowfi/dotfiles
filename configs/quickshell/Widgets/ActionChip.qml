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
    color: accent
           ? (acMa.pressed ? Qt.darker(Theme.yellow, 1.3)
              : acMa.containsMouse && enabled ? Qt.darker(Theme.yellow, 1.12)
              : Theme.yellow)
           : (acMa.pressed ? Theme.bg3
              : acMa.containsMouse && enabled ? Theme.bg2
              : Theme.bg1)
    Behavior on color { ColorAnimation { duration: 100 } }
    scale: acMa.pressed ? 0.94 : 1
    Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }
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
