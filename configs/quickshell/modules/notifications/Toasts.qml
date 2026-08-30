import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../../Services"

PanelWindow {
        anchors { top: true; right: true }
        margins { top: Theme.barHeight + 8; right: 8 }
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: 360
        implicitHeight: Math.max(1, toastCol.implicitHeight)
        visible: NotifSvc.notifServer.trackedNotifications.values.length > 0 && !NotifSvc.doNotDisturb
        color: "transparent"

        ColumnLayout {
            id: toastCol
            width: parent.width
            spacing: 8
            Repeater {
                model: NotifSvc.notifServer.trackedNotifications
                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: tInner.implicitHeight + 20
                    radius: 8
                    color: Theme.bg1
                    border.width: 1
                    border.color: modelData.urgency === NotificationUrgency.Critical ? Theme.red : Theme.bg2
                    ColumnLayout {
                        id: tInner
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                        spacing: 2
                        Text {
                            Layout.fillWidth: true
                            text: modelData.appName + (modelData.summary ? "  ·  " + modelData.summary : "")
                            color: Theme.yellow; elide: Text.ElideRight
                            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: modelData.body !== ""
                            text: modelData.body
                            color: Theme.fg; wrapMode: Text.Wrap
                            maximumLineCount: 4; elide: Text.ElideRight
                            textFormat: Text.PlainText
                            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
                        }
                    }
                    MouseArea { anchors.fill: parent; onClicked: modelData.dismiss() }
                    Timer {
                        interval: modelData.urgency === NotificationUrgency.Critical ? 30000 : 6000
                        running: true
                        onTriggered: modelData.expire()
                    }
                }
            }
        }
    }
