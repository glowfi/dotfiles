import QtQuick
import "../Services"

Rectangle {
    property bool on: false
    signal clicked()
    implicitWidth: 64
    implicitHeight: 28
    radius: 14
    color: on ? Theme.green : Theme.bg2
    Rectangle {
        width: 22; height: 22; radius: 11
        anchors.verticalCenter: parent.verticalCenter
        x: parent.on ? parent.width - width - 3 : 3
        color: Theme.fg0
        Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        x: parent.on ? 8 : parent.width - width - 8
        text: parent.on ? "on" : "off"
        color: parent.on ? Theme.bg0 : Theme.fgDim
        font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 4 }
    }
    MouseArea { anchors.fill: parent; onClicked: parent.clicked() }
}
