import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../Services"

// One per screen: renders the shared tooltip just below the bar, centered
// under the hovered widget. Empty mask = fully click-through.
PanelWindow {
    id: tipWindow
    property var modelData: null
    screen: modelData
    anchors { top: true; left: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"
    mask: Region {}

    visible: TipSvc.shown && screen
             && (TipSvc.screenName === "" || TipSvc.screenName === screen.name)
    implicitWidth: tipText.implicitWidth + 18
    implicitHeight: 26
    margins {
        top: Theme.barHeight + 2
        left: Math.max(8, Math.min(TipSvc.cx - implicitWidth / 2,
                                   (screen ? screen.width : 0) - implicitWidth - 8))
    }

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: Theme.bg0h
        border.width: 1
        border.color: Theme.bg2
        Text {
            id: tipText
            anchors.centerIn: parent
            text: TipSvc.text
            color: Theme.fg
            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 3 }
        }
    }
}
