// Template popup. Opens under its pill via bar.togglePopupAt().
// PanelWindow = positionable + can take keyboard; use PopupWindow only
// for simple menus anchored to the bar window.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../Services"
import "../../Widgets"

PanelWindow {
    id: examplePopup
    required property var bar
    screen: bar.screen
    anchors { top: true; left: true }
    margins { top: Theme.barHeight + 4; left: 8 }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    implicitWidth: 300
    implicitHeight: col.implicitHeight + 28
    visible: false
    color: Theme.bg0h

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        spacing: 8
        SectionLabel { text: "EXAMPLE" }
        InfoPair { label: "hello"; value: "world" }
    }
}
