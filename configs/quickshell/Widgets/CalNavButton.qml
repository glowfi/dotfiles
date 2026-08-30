import QtQuick
import "../Services"

Rectangle {
    property string text
    signal clicked()
    implicitWidth: 32
    implicitHeight: 32
    radius: 6
    color: navMa.containsMouse ? Theme.bg2 : Theme.bg1
    Behavior on color { ColorAnimation { duration: 120 } }
    Text {
        anchors.centerIn: parent
        text: parent.text
        color: Theme.fg
        font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize + 2 }
    }
    MouseArea {
        id: navMa
        anchors.fill: parent
        hoverEnabled: true
        onClicked: parent.clicked()
    }
}
