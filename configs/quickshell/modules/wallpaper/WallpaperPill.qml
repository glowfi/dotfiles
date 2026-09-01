import QtQuick
import "../../Services"
import "../../Widgets"

BarButton {
    id: wallPill
    required property var bar
    required property var popup

    text: "󰸉"
    px: Theme.iconSize
    fgColor: Theme.purple
    tooltip: "wallpapers"
    onClicked: {
        Wallpaper.rescan();
        bar.togglePopupAt(popup, wallPill);
    }
}
