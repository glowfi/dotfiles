// Icon-only taskbar with per-app grouping. One button per appId; a count
// badge appears when an app has multiple windows. Click focuses (and cycles
// through the group's windows on repeat clicks), middle-click closes the
// group's focused window.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../../Services"

ListView {
    id: taskbar
    Layout.fillWidth: true
    Layout.fillHeight: true
    orientation: ListView.Horizontal
    clip: true
    spacing: 6

    model: ScriptModel {
        values: {
            const groups = {};
            const order = [];
            for (const t of ToplevelManager.toplevels.values) {
                const key = t.appId || t.title || "?";
                if (!groups[key]) {
                    groups[key] = { appId: key, windows: [] };
                    order.push(groups[key]);
                }
                groups[key].windows.push(t);
            }
            return order;
        }
    }

    delegate: Rectangle {
        id: task
        required property var modelData
        readonly property var wins: modelData.windows
        readonly property bool grpActive: wins.some(w => w.activated)
        readonly property var dEntry: {
            try { return DesktopEntries.heuristicLookup(modelData.appId); }
            catch (e) { return null; }
        }
        readonly property string iconSrc:
            (dEntry && dEntry.icon) ? Quickshell.iconPath(dEntry.icon, true) : ""

        function focusOrCycle() {
            const idx = wins.findIndex(w => w.activated);
            if (idx < 0) wins[0].activate();
            else wins[(idx + 1) % wins.length].activate();   // repeat clicks cycle the group
        }

        width: Theme.barHeight - 6
        height: Theme.barHeight - 8
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        radius: 6
        color: grpActive ? Theme.bg2 : (taskMa.containsMouse ? Theme.bg1 : "transparent")

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
            text: (task.modelData.appId || "?").charAt(0).toUpperCase()
            color: task.grpActive ? Theme.yellow : Theme.fg
            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.iconSize - 4 }
        }

        // multi-window badge
        Rectangle {
            visible: task.wins.length > 1
            anchors { top: parent.top; right: parent.right; topMargin: 0; rightMargin: 0 }
            width: badge.width + 8
            height: 16
            radius: 8
            color: Theme.yellow
            Text {
                id: badge
                anchors.centerIn: parent
                text: task.wins.length
                color: Theme.bg0
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 6 }
            }
        }
        // focused-window underline
        Rectangle {
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
            width: parent.width - 12
            height: 3
            radius: 1.5
            color: Theme.yellow
            visible: task.grpActive
        }

        MouseArea {
            id: taskMa
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onClicked: ev => {
                if (ev.button === Qt.MiddleButton) {
                    const focused = task.wins.find(w => w.activated);
                    (focused ?? task.wins[task.wins.length - 1]).close();
                } else {
                    task.focusOrCycle();
                }
            }
        }
        ToolTip.visible: taskMa.containsMouse
        ToolTip.text: task.wins.map(w => "• " + (w.title || task.modelData.appId)).join("\n")
        ToolTip.delay: 700
    }
}
