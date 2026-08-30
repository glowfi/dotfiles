import QtQuick
import QtQuick.Layouts
import "../Services"

RowLayout {
    property string icon
    property string value
    spacing: 5
    Text {
        text: parent.icon
        color: Theme.fg0
        font { family: Theme.fontFamily; bold: true; pixelSize: Theme.iconSize - 2 }
    }
    Text {
        text: parent.value
        color: Theme.fg
        font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
    }
}
