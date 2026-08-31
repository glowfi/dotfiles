import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../Services"
import "../../Widgets"
import Quickshell.Widgets

// Layer window like every other popup: xdg-popups resize with blurred
// buffers on fractional scale; layer surfaces (see the resolution
// dropdown) resize cleanly. Inline submenu expansion needs that.
PanelWindow {
    id: trayMenuPopup
    required property var bar
    property var handle: null
    property real pendingX: 0

    screen: bar.screen
    anchors { top: true; left: true }
    margins { top: Theme.barHeight + 4; left: 8 }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    implicitWidth: 280
    implicitHeight: Math.min(560, trayMenuCol.implicitHeight + 16)
    visible: false
    color: Theme.bg0h

    // DBus menus populate asynchronously: set the handle first, give the
    // layout a beat to arrive, then map once at settled size.
    function openFor(item, x) {
        bar.closeAllPopups();
        handle = item.menu;
        pendingX = x;
        openDelay.restart();
    }
    Timer {
        id: openDelay
        interval: 90
        onTriggered: {
            trayMenuPopup.margins.left =
                Math.max(8, Math.min(trayMenuPopup.pendingX,
                                     bar.width - trayMenuPopup.implicitWidth - 8));
            trayMenuPopup.visible = true;
        }
    }

    QsMenuOpener {
        id: trayOpener
        menu: trayMenuPopup.handle
    }

    ColumnLayout {
        id: trayMenuCol
        anchors.fill: parent
        anchors.margins: 8
        spacing: 2

        Repeater {
            model: trayOpener.children
            delegate: ColumnLayout {
                id: menuNode
                required property var modelData
                property bool expanded: false
                Layout.fillWidth: true
                spacing: 2

                TrayMenuRow {
                    entry: menuNode.modelData
                    submenuOpen: menuNode.expanded
                    onActivated: {
                        if (menuNode.modelData.hasChildren) {
                            menuNode.expanded = !menuNode.expanded;
                        } else {
                            menuNode.modelData.triggered();
                            bar.closeAllPopups();
                        }
                    }
                }

                QsMenuOpener {
                    id: subOpener
                    menu: menuNode.modelData
                }
                Repeater {
                    model: menuNode.expanded ? subOpener.children : null
                    delegate: TrayMenuRow {
                        required property var modelData
                        entry: modelData
                        Layout.leftMargin: 22
                        onActivated: {
                            modelData.triggered();
                            bar.closeAllPopups();
                        }
                    }
                }
            }
        }

        Text {
            visible: trayOpener.children.values.length === 0
            text: "no actions"
            color: Theme.gray
            Layout.margins: 8
            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
        }
    }
}
