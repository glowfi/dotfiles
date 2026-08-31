import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Services"

Rectangle {
    property string icon
    property string value
    property color iconColor: Theme.fg0
    property int maxValueWidth: 400
    property int iconPx: Theme.iconSize - 2
    property string tooltip: ""
    signal clicked()
    signal rightClicked()
    signal wheelMoved(real delta)
    implicitWidth: pillRow.implicitWidth + 16
    implicitHeight: 30
    radius: 4
    color: pillMa.containsMouse ? Theme.bg1 : "transparent"
    RowLayout {
        id: pillRow
        anchors.centerIn: parent
        spacing: 6
        Text {
            text: parent.parent.icon
            color: parent.parent.iconColor
            font { family: Theme.fontFamily; bold: true; pixelSize: parent.parent.iconPx }
        }
        Text {
            text: parent.parent.value
            color: Theme.fg
            elide: Text.ElideRight
            Layout.maximumWidth: parent.parent.maxValueWidth
            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
        }
    }
    MouseArea {
        id: pillMa
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: ev => ev.button === Qt.RightButton ? parent.rightClicked() : parent.clicked()
        onWheel: ev => parent.wheelMoved(ev.angleDelta.y)
    }
    ToolTip.visible: tooltip !== "" && pillMa.containsMouse
    ToolTip.text: tooltip
    ToolTip.delay: 700
}
