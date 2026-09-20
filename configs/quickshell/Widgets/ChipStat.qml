import QtQuick
import QtQuick.Layouts
import "../Services"

RowLayout {
    id: chipStat
    property string icon
    property string value
    property string tooltip: ""
    readonly property var winRef: Window.window
    spacing: 5

    Text {
        text: chipStat.icon
        color: Theme.fg0
        font { family: Theme.fontFamily; bold: true; pixelSize: Theme.iconSize - 2 }
    }
    Text {
        text: chipStat.value
        color: Theme.fg
        font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
    }

    MouseArea {
        id: chipMa
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton   // hover only: stays display-only
        onContainsMouseChanged: if (!containsMouse) TipSvc.hide()
    }
    Timer {
        interval: 600
        running: chipMa.containsMouse && chipStat.tooltip !== ""
        onTriggered: TipSvc.show(chipStat.tooltip,
            chipStat.mapToItem(null, 0, 0).x + chipStat.width / 2,
            chipStat.winRef && chipStat.winRef.screen
                ? chipStat.winRef.screen.name : "")
    }
}
