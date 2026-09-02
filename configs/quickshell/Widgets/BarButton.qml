import QtQuick
import QtQuick.Controls
import "../Services"

Rectangle {
    property string text
    property color fgColor: Theme.fg
    property string tooltip: ""
    property int px: Theme.fontSize
    signal clicked()
    signal rightClicked()
    signal middleClicked()
    implicitWidth: btnText.width + 18
    implicitHeight: 30
    radius: 4
    color: btnMa.containsMouse ? Theme.bg1 : "transparent"
    Behavior on color { ColorAnimation { duration: 120 } }
    Text {
        id: btnText
        anchors.centerIn: parent
        text: parent.text
        color: parent.fgColor
        font { family: Theme.fontFamily; bold: true; pixelSize: parent.px }
    }
    MouseArea {
        id: btnMa
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: ev => {
            if (ev.button === Qt.RightButton) parent.rightClicked();
            else if (ev.button === Qt.MiddleButton) parent.middleClicked();
            else parent.clicked();
        }
    }
    ToolTip {
        visible: tooltip !== "" && btnMa.containsMouse
        text: tooltip
        delay: 600
        padding: 8
        background: Rectangle {
            color: Theme.bg0h
            radius: 6
            border.width: 1
            border.color: Theme.bg2
        }
        contentItem: Text {
            text: tooltip
            color: Theme.fg
            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 3 }
        }
    }
}
