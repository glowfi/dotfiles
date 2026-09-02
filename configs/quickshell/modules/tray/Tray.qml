import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../Services"
import "../../Widgets"
import Quickshell.Services.SystemTray
import Quickshell.Widgets

RowLayout {
    id: trayRoot
    visible: SystemTray.items.values.length > 0
    required property var bar
    required property var menuPopup

    // Hide unwanted tray items by substring match against id/title/tooltip
    // (case-insensitive). Hover an icon to learn its name, then add it here.
    readonly property var blocklist: ["mic"]
    function blocked(item) {
        const hay = ((item.id ?? "") + " " + (item.title ?? "") + " "
                     + (item.tooltipTitle ?? "")).toLowerCase();
        return blocklist.some(b => hay.includes(b.toLowerCase()));
    }
    spacing: 6
    Repeater {
        model: SystemTray.items
        Item {
            id: trayItem
            required property var modelData
            // hide Passive items: apps register helper SNIs (mic/recording
            // indicators etc.) as Passive, meaning "exists, don't display"
            visible: modelData.status !== Status.Passive && !trayRoot.blocked(modelData)
            // track the panel font instead of a fixed 30px; icons rendered
            // larger than their source bitmaps are what caused the blur
            width: Theme.iconSize - 2
            height: Theme.iconSize - 2
            IconImage {
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                source: trayItem.modelData.icon
                asynchronous: true
            }
            function openMenu() {
                const p = trayItem.mapToItem(null, 0, 0);
                menuPopup.openFor(trayItem.modelData, p.x);
            }
            MouseArea {
                id: trayItemMa
                anchors.fill: parent
                hoverEnabled: true
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
            ToolTip {
                visible: trayItemMa.containsMouse
                delay: 800
                padding: 8
                background: Rectangle {
                    color: Theme.bg0h
                    radius: 6
                    border.width: 1
                    border.color: Theme.bg2
                }
                contentItem: Text {
                    text: trayItem.modelData.tooltipTitle || trayItem.modelData.title
                          || trayItem.modelData.id || "tray item"
                    color: Theme.fg
                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 3 }
                }
            }
        }
    }
}
