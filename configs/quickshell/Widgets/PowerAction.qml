import QtQuick
import QtQuick.Layouts
import Quickshell
import "../Services"

Rectangle {
    property string label
    property var cmd
    property var popup
    Layout.fillWidth: true
    implicitHeight: 36
    radius: 5
    color: paMa.containsMouse ? Theme.bg2 : "transparent"
    Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 8
        text: parent.label
        color: Theme.fg
        font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
    }
    MouseArea {
        id: paMa
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            Quickshell.execDetached(parent.cmd);
            if (parent.popup) parent.popup.visible = false;
        }
    }
}
