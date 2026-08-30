import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../Services"
import "../../Widgets"
import Quickshell.Widgets

//            unreliable on wlroots layer-shell) ----------
PopupWindow {
    required property var bar
    property var handle: null
    function openFor(item, x) {
        bar.closeAllPopups();
        handle = item.menu;
        anchor.rect.x = Math.min(x, bar.width - implicitWidth - 8);
        visible = true;
    }
    id: trayMenuPopup
    anchor.window: bar
    anchor.rect.y: Theme.barHeight
    implicitWidth: 280
    implicitHeight: Math.min(560, trayMenuCol.implicitHeight + 16)
    visible: false
    color: Theme.bg0h

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
