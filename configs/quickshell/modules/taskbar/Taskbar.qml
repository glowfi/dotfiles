import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../Services"
import "../../Widgets"
import Quickshell.Wayland
import Quickshell.Widgets

ListView {
    Layout.fillWidth: true
    Layout.fillHeight: true
    orientation: ListView.Horizontal
    clip: true
    spacing: 6
    model: ToplevelManager.toplevels
    delegate: Rectangle {
        id: task
        required property var modelData
        readonly property var dEntry: {
            try { return DesktopEntries.heuristicLookup(modelData.appId); }
            catch (e) { return null; }
        }
        readonly property string iconSrc:
            (dEntry && dEntry.icon) ? Quickshell.iconPath(dEntry.icon, true) : ""
        width: Theme.barHeight - 6
        height: Theme.barHeight - 8
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        radius: 6
        color: modelData.activated ? Theme.bg2 : (taskMa.containsMouse ? Theme.bg1 : "transparent")
        IconImage {
            anchors.centerIn: parent
            width: Theme.iconSize + 2
            height: Theme.iconSize + 2
            source: task.iconSrc
            visible: task.iconSrc !== ""
        }
        Text {
            anchors.centerIn: parent
            visible: task.iconSrc === ""
            text: (modelData.appId || modelData.title || "?").charAt(0).toUpperCase()
            color: modelData.activated ? Theme.yellow : Theme.fg
            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.iconSize - 4 }
        }
        Rectangle {
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
            width: parent.width - 12
            height: 3
            radius: 1.5
            color: Theme.yellow
            visible: modelData.activated
        }
        MouseArea {
            id: taskMa
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onClicked: ev => {
                if (ev.button === Qt.MiddleButton) modelData.close();
                else modelData.activate();
            }
        }
        ToolTip.visible: taskMa.containsMouse
        ToolTip.text: modelData.title || modelData.appId || ""
        ToolTip.delay: 700
    }
}
