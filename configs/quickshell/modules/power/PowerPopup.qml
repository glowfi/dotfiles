import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Services"
import "../../Widgets"

PopupWindow {
    required property var bar
    id: powerPopup
    anchor.window: bar
    anchor.rect.x: bar.width - 210
    anchor.rect.y: Theme.barHeight
    implicitWidth: 200
    implicitHeight: powerCol.implicitHeight + 16
    visible: false
    color: Theme.bg0h

    ColumnLayout {
        id: powerCol
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4
        PowerAction { label: "󰌾  Lock";       cmd: ["sh", "-c", "kitty --class screensaver --start-as fullscreen -o background_opacity=1 bash \"$HOME/.local/bin/screensaver.sh\""]; popup: powerPopup }
        PowerAction { label: "󰜉  Reboot";     cmd: ["systemctl", "reboot"];         popup: powerPopup }
        PowerAction { label: "⏻  Shutdown";   cmd: ["systemctl", "poweroff"];       popup: powerPopup }
        PowerAction { label: "󰗼  Exit mango"; cmd: ["mmsg", "dispatch", "quit"];    popup: powerPopup }
    }
}
