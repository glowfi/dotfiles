// Clipboard history with fuzzy search. Layer window (not PopupWindow):
// xdg popups never receive keyboard input, so a search field needs this.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../../Services"
import "../../Widgets"

PanelWindow {
    id: clipPopup
    required property var bar
    screen: bar.screen
    anchors { top: true; right: true }
    margins { top: Theme.barHeight + 4; right: 8 }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    implicitWidth: 480
    implicitHeight: 460
    visible: false
    color: Theme.bg0h

    function focusSearch() { clipSearch.forceActiveFocus() }
    onVisibleChanged: if (!visible) clipSearch.text = ""

    // subsequence fuzzy match: every query char appears in order
    function fuzzy(hay, q) {
        hay = hay.toLowerCase();
        let i = 0;
        for (const c of q.toLowerCase()) {
            i = hay.indexOf(c, i);
            if (i < 0) return false;
            i++;
        }
        return true;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        Text {
            text: "Clipboard history  (click to copy)"
            color: Theme.purple
            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 36
            radius: 6
            color: Theme.bg1
            border.width: 1
            border.color: clipSearch.activeFocus ? Theme.yellow : Theme.bg2
            TextInput {
                id: clipSearch
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.fg
                clip: true
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
                onAccepted: {
                    if (clipList.count > 0) {
                        const item = clipList.itemAtIndex(0);
                        if (item) item.copyIt();
                    }
                }
                Keys.onEscapePressed: clipPopup.visible = false
                Text {
                    visible: clipSearch.text === ""
                    text: "fuzzy search…"
                    color: Theme.gray
                    anchors.verticalCenter: parent.verticalCenter
                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
                }
            }
        }

        ListView {
            id: clipList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            ScrollBar.vertical: GruvScrollBar {}
            model: ScriptModel {
                values: Clip.clipEntries.filter(e =>
                    clipSearch.text === "" || clipPopup.fuzzy(e.preview, clipSearch.text))
            }
            delegate: Rectangle {
                required property var modelData
                function copyIt() {
                    Clip.copyClip(modelData.cid);
                    clipPopup.visible = false;
                }
                width: clipList.width - 10
                height: 38
                radius: 5
                color: clMa.containsMouse ? Theme.bg1 : "transparent"
                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    text: modelData.preview
                    color: Theme.fg
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
                }
                MouseArea {
                    id: clMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: parent.copyIt()
                }
            }
            Text {
                anchors.centerIn: parent
                visible: clipList.count === 0
                text: Clip.clipEntries.length === 0
                      ? "empty — is `wl-paste --watch cliphist store` running?"
                      : "no match"
                color: Theme.gray
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
            }
        }
    }
}
