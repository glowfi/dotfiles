import QtQuick
import QtQuick.Controls
import "../Services"

Rectangle {
    id: barBtnRoot
    // attached properties are only valid unqualified in the owner's scope —
    // capture the window here, use the captured ref everywhere else
    readonly property var winRef: Window.window
    property string text
    property color fgColor: Theme.fg
    property string tooltip: ""
    property int px: Theme.fontSize
    signal clicked()
    signal rightClicked()
    signal middleClicked()
    implicitWidth: btnText.width + 18
    implicitHeight: 30
    radius: 4
    color: btnMa.containsMouse ? Theme.bg1 : "transparent"
    Behavior on color { ColorAnimation { duration: 120 } }
    Text {
        id: btnText
        anchors.centerIn: parent
        text: parent.text
        color: parent.fgColor
        font { family: Theme.fontFamily; bold: true; pixelSize: parent.px }
    }
    MouseArea {
        id: btnMa
        anchors.fill: parent
        hoverEnabled: true
        onContainsMouseChanged: if (!containsMouse) TipSvc.hide()
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onPressed: TipSvc.hide()
        onClicked: ev => {
            if (ev.button === Qt.RightButton) parent.rightClicked();
            else if (ev.button === Qt.MiddleButton) parent.middleClicked();
            else parent.clicked();
        }
    }
    Timer {
        interval: 600
        running: btnMa.containsMouse && tooltip !== ""
        onTriggered: TipSvc.show(barBtnRoot.tooltip,
            barBtnRoot.mapToItem(null, 0, 0).x + barBtnRoot.width / 2,
            barBtnRoot.winRef && barBtnRoot.winRef.screen
                ? barBtnRoot.winRef.screen.name : "")
    }
}
