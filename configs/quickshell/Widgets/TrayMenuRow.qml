import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../Services"

Rectangle {
    property var entry
    property bool submenuOpen: false
    signal activated()
    readonly property bool sep: entry ? entry.isSeparator : false
    Layout.fillWidth: true
    implicitHeight: sep ? 9 : 36
    radius: 4
    color: !sep && rowMa.containsMouse && entry && entry.enabled ? Theme.bg2 : "transparent"

    Rectangle {
        visible: parent.sep
        anchors.centerIn: parent
        width: parent.width - 8
        height: 1
        color: Theme.bg2
    }
    RowLayout {
        visible: !parent.sep
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8
        Text {
            visible: text !== ""
            text: parent.parent.entry && parent.parent.entry.checkState === Qt.Checked ? "󰄬" : ""
            color: Theme.green
            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
        }
        IconImage {
            visible: parent.parent.entry && parent.parent.entry.icon !== ""
            source: parent.parent.entry ? parent.parent.entry.icon : ""
            implicitSize: 20
        }
        Text {
            Layout.fillWidth: true
            text: parent.parent.entry ? parent.parent.entry.text.replace(/&/g, "") : ""
            color: parent.parent.entry && parent.parent.entry.enabled ? Theme.fg : Theme.gray
            elide: Text.ElideRight
            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
        }
        Text {
            visible: parent.parent.entry ? parent.parent.entry.hasChildren : false
            text: parent.parent.submenuOpen ? "⌄" : "›"
            color: Theme.fgDim
            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
        }
    }
    MouseArea {
        id: rowMa
        anchors.fill: parent
        hoverEnabled: true
        enabled: parent.entry ? (parent.entry.enabled && !parent.sep) : false
        onClicked: parent.activated()
    }
}
