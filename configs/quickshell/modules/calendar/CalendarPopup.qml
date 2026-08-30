import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../Services"
import "../../Widgets"

PopupWindow {
    required property var bar
    id: calPopup
    anchor.window: bar
    anchor.rect.x: bar.width - 400
    anchor.rect.y: Theme.barHeight
    implicitWidth: 390
    implicitHeight: 420
    visible: false
    color: Theme.bg0h

    property int viewMonth: Clock.date.getMonth()
    property int viewYear: Clock.date.getFullYear()
    onVisibleChanged: if (visible) {
        viewMonth = Clock.date.getMonth();
        viewYear = Clock.date.getFullYear();
    }
    function shiftMonth(d) {
        let m = viewMonth + d;
        while (m < 0)  { m += 12; viewYear--; }
        while (m > 11) { m -= 12; viewYear++; }
        viewMonth = m;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        // ---- header: « ‹ Month Year › » + today ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            CalNavButton { text: "«"; onClicked: calPopup.viewYear-- }
            CalNavButton { text: "‹"; onClicked: calPopup.shiftMonth(-1) }
            Item {
                Layout.fillWidth: true
                implicitHeight: 32
                Text {
                    anchors.centerIn: parent
                    text: Qt.locale().monthName(calPopup.viewMonth) + " " + calPopup.viewYear
                    color: Theme.yellow
                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize + 1 }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        calPopup.viewMonth = Clock.date.getMonth();
                        calPopup.viewYear = Clock.date.getFullYear();
                    }
                }
            }
            CalNavButton { text: "›"; onClicked: calPopup.shiftMonth(1) }
            CalNavButton { text: "»"; onClicked: calPopup.viewYear++ }
        }

        DayOfWeekRow {
            Layout.fillWidth: true
            delegate: Text {
                required property var model
                text: model.shortName
                color: Theme.fgDim
                horizontalAlignment: Text.AlignHCenter
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 2 }
            }
        }

        MonthGrid {
            id: calGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            month: calPopup.viewMonth
            year: calPopup.viewYear
            delegate: Item {
                id: dayCell
                required property var model
                readonly property bool inMonth: model.month === calGrid.month

                Rectangle {
                    id: dayBg
                    anchors.centerIn: parent
                    width: 34; height: 34; radius: 17
                    color: model.today ? Theme.yellow
                         : dayMa.containsMouse ? Theme.bg2
                         : "transparent"
                    scale: dayMa.containsMouse ? 1.12 : 1.0
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on scale {
                        NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: model.day
                    opacity: dayCell.inMonth ? 1 : (dayMa.containsMouse ? 0.7 : 0.3)
                    color: model.today ? Theme.bg0
                         : dayMa.containsMouse ? Theme.fg0
                         : Theme.fg
                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }
                MouseArea {
                    id: dayMa
                    anchors.fill: parent
                    hoverEnabled: true
                    // click a spillover day -> browse to its month
                    onClicked: if (!dayCell.inMonth) {
                        calPopup.viewMonth = dayCell.model.month;
                        calPopup.viewYear = dayCell.model.year;
                    }
                }
            }
        }

        // today shortcut
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 110; implicitHeight: 30; radius: 6
            color: todayMa.containsMouse ? Theme.bg2 : Theme.bg1
            Behavior on color { ColorAnimation { duration: 120 } }
            Text {
                anchors.centerIn: parent
                text: Qt.formatDate(Clock.date, "dd MMM yyyy")
                color: Theme.fgDim
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 3 }
            }
            MouseArea {
                id: todayMa
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    calPopup.viewMonth = Clock.date.getMonth();
                    calPopup.viewYear = Clock.date.getFullYear();
                }
            }
        }
    }
}
