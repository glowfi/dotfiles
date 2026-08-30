import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../Services"
import "../../Widgets"
import Quickshell.Services.SystemTray
import Quickshell.Widgets

RowLayout {
    required property var bar
    required property var menuPopup
    spacing: 6
    Repeater {
        model: SystemTray.items
        Item {
            id: trayItem
            required property var modelData
            width: 30; height: 30
            IconImage {
                anchors.fill: parent
                source: trayItem.modelData.icon
                smooth: true
                asynchronous: true
            }
            function openMenu() {
                const p = trayItem.mapToItem(null, 0, 0);
                menuPopup.openFor(trayItem.modelData, p.x);
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: ev => {
                    const item = trayItem.modelData;
                    if (ev.button === Qt.RightButton) {
                        if (item.hasMenu) trayItem.openMenu();
                        else item.secondaryActivate();
                    } else if (ev.button === Qt.MiddleButton) {
                        item.secondaryActivate();
                    } else {
                        if (item.onlyMenu && item.hasMenu) trayItem.openMenu();
                        else item.activate();
                    }
                }
            }
            ToolTip.visible: false
        }
    }
}
