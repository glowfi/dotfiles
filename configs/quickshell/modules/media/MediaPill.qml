import QtQuick
import "../../Services"
import "../../Widgets"

BarButton {
    id: mediaPill
    required property var bar
    required property var popup

    visible: MediaSvc.hasMedia
    text: "󰝚"
    px: Theme.iconSize
    fgColor: MediaSvc.activePlayer && MediaSvc.activePlayer.isPlaying ? Theme.green : Theme.fgDim
    tooltip: {
        const p = MediaSvc.activePlayer;
        if (!p) return "media";
        const t = p.trackTitle ?? "", a = p.trackArtist ?? "";
        return a !== "" ? t + " — " + a : t;
    }
    onClicked: bar.togglePopupAt(popup, mediaPill)
}
