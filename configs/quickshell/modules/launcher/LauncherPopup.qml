import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../Services"
import "../../Widgets"
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    required property var bar
    function focusSearch() { launchSearch.forceActiveFocus() }
    id: launcherPopup
    screen: bar.screen
    anchors { top: true; left: true }
    margins { top: Theme.barHeight + 4; left: 8 }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    implicitWidth: 460
    implicitHeight: 560
    visible: false
    color: Theme.bg0h

    onVisibleChanged: if (!visible) launchSearch.text = ""

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 40
            radius: 6
            color: Theme.bg1
            border.width: 1
            border.color: launchSearch.activeFocus ? Theme.yellow : Theme.bg2
            TextInput {
                id: launchSearch
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.fg
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
                clip: true
                onAccepted: {
                    if (launchList.count > 0) {
                        const item = launchList.itemAtIndex(0);
                        if (item) item.launch();
                    }
                }
                Keys.onEscapePressed: launcherPopup.visible = false
                Text {
                    visible: launchSearch.text === ""
                    text: "search apps…"
                    color: Theme.gray
                    anchors.verticalCenter: parent.verticalCenter
                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
                }
            }
        }

        ListView {
            id: launchList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.vertical: GruvScrollBar {}
            spacing: 2
            model: ScriptModel {
                values: {
                    const q = launchSearch.text.toLowerCase();
                    return [...DesktopEntries.applications.values]
                        .filter(e => !e.noDisplay &&
                            (q === "" || e.name.toLowerCase().includes(q)))
                        .sort((a, b) => a.name.localeCompare(b.name));
                }
            }
            delegate: Rectangle {
                required property var modelData
                function launch() { modelData.execute(); launcherPopup.visible = false }
                width: launchList.width
                height: 44
                radius: 6
                color: appMa.containsMouse ? Theme.bg1 : "transparent"
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8
                    IconImage {
                        width: 28; height: 28
                        source: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData.name
                        color: Theme.fg
                        elide: Text.ElideRight
                        font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
                    }
                }
                MouseArea {
                    id: appMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: parent.launch()
                }
            }
        }
    }
}
