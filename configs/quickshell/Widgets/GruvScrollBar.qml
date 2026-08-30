import QtQuick
import QtQuick.Controls
import "../Services"

ScrollBar {
    id: sb
    policy: ScrollBar.AsNeeded
    contentItem: Rectangle {
        implicitWidth: 8
        radius: 4
        color: sb.pressed ? Theme.yellow : (sb.hovered ? Theme.bg3 : Theme.bg2)
    }
    background: Rectangle {
        implicitWidth: 8
        radius: 4
        color: Theme.bg0
    }
}
