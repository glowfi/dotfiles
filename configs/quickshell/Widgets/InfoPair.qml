import QtQuick
import QtQuick.Layouts
import "../Services"

RowLayout {
    property string label
    property string value
    Layout.fillWidth: true
    spacing: 8
    Text {
        text: parent.label
        color: Theme.fgDim
        font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 2 }
        Layout.preferredWidth: 150
    }
    Text {
        Layout.fillWidth: true
        text: parent.value
        color: Theme.fg
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignRight
        font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 2 }
    }
}
