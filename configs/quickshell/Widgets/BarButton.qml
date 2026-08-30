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
    ToolTip.visible: tooltip !== "" && btnMa.containsMouse
    ToolTip.text: tooltip
    ToolTip.delay: 600
}
