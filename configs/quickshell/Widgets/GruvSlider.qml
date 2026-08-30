import QtQuick
import "../Services"

Item {
    id: slider
    property real value: 0            // 0..1
    signal moved(real v)
    implicitHeight: 26
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 5
        radius: 2.5
        color: Theme.bg2
    }
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, Math.min(1, slider.value)) * parent.width
        height: 5
        radius: 2.5
        color: Theme.yellow
    }
    Rectangle {
        x: Math.max(0, Math.min(1, slider.value)) * (parent.width - width)
        anchors.verticalCenter: parent.verticalCenter
        width: 18; height: 18; radius: 9
        color: Theme.fg
        border.width: 2
        border.color: Theme.bg0
    }
    MouseArea {
        anchors.fill: parent
        function emitPos(mx) { slider.moved(Math.max(0, Math.min(1, mx / slider.width))) }
        onPressed: ev => emitPos(ev.x)
        onPositionChanged: ev => { if (pressed) emitPos(ev.x) }
    }
}
