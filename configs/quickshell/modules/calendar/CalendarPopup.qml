import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../../Services"
import "../../Widgets"

PanelWindow {
    required property var bar
    id: calPopup
    screen: bar.screen
    anchors { top: true; left: true }
    margins { top: Theme.barHeight + 4; left: 8 }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    implicitWidth: 390
    implicitHeight: 420
    visible: false
    color: "transparent"

    // popup surface: rounded + hairline border (windows are transparent)
    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Theme.bg0h
        border.width: 1
        border.color: Theme.bg2
    }

    property int viewMonth: Clock.date.getMonth()
    property int viewYear: Clock.date.getFullYear()
    // "days" | "months" | "years" — title click drills up, picking drills down
    property string mode: "days"
    property int yearPage: 0        // years view: page offset in 12-year steps
    onVisibleChanged: if (visible) {
        viewMonth = Clock.date.getMonth();
        viewYear = Clock.date.getFullYear();
        mode = "days";
        yearPage = 0;
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

        // ---- header: nav + drill-up title (day->month picker->year picker) ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            CalNavButton {
                text: "«"
                onClicked: {
                    if (calPopup.mode === "years") calPopup.yearPage -= 1;
                    else calPopup.viewYear--;
                }
            }
            CalNavButton {
                text: "‹"
                visible: calPopup.mode === "days"
                onClicked: calPopup.shiftMonth(-1)
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 32
                radius: 6
                color: titleMa.containsMouse && calPopup.mode !== "years" ? Theme.bg1 : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
                Text {
                    anchors.centerIn: parent
                    text: {
                        if (calPopup.mode === "days")
                            return Qt.locale().monthName(calPopup.viewMonth) + " " + calPopup.viewYear + "  ▾";
                        if (calPopup.mode === "months")
                            return calPopup.viewYear + "  ▾";
                        const base = calPopup.viewYear - 5 + calPopup.yearPage * 12;
                        return base + " – " + (base + 11);
                    }
                    color: Theme.yellow
                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize + 1 }
                }
                MouseArea {
                    id: titleMa
                    anchors.fill: parent
                    hoverEnabled: true
                    // days -> pick a month; months -> pick a year
                    onClicked: {
                        if (calPopup.mode === "days") calPopup.mode = "months";
                        else if (calPopup.mode === "months") { calPopup.yearPage = 0; calPopup.mode = "years"; }
                    }
                }
            }
            CalNavButton {
                text: "›"
                visible: calPopup.mode === "days"
                onClicked: calPopup.shiftMonth(1)
            }
            CalNavButton {
                text: "»"
                onClicked: {
                    if (calPopup.mode === "years") calPopup.yearPage += 1;
                    else calPopup.viewYear++;
                }
            }
        }

        DayOfWeekRow {
            visible: calPopup.mode === "days"
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
            visible: calPopup.mode === "days"
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

        // ---- month picker ----
        GridLayout {
            visible: calPopup.mode === "months"
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 3
            rowSpacing: 8
            columnSpacing: 8
            Repeater {
                model: 12
                Rectangle {
                    required property int index
                    readonly property bool current:
                        index === Clock.date.getMonth()
                        && calPopup.viewYear === Clock.date.getFullYear()
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8
                    color: current ? Theme.yellow
                         : monMa.containsMouse ? Theme.bg2 : Theme.bg1
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        anchors.centerIn: parent
                        text: Qt.locale().monthName(parent.index, Locale.ShortFormat)
                        color: parent.current ? Theme.bg0 : Theme.fg
                        font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
                    }
                    MouseArea {
                        id: monMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            calPopup.viewMonth = parent.index;
                            calPopup.mode = "days";
                        }
                    }
                }
            }
        }

        // ---- year picker (12 years per page) ----
        GridLayout {
            visible: calPopup.mode === "years"
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 3
            rowSpacing: 8
            columnSpacing: 8
            Repeater {
                model: 12
                Rectangle {
                    required property int index
                    readonly property int yr: calPopup.viewYear - 5 + calPopup.yearPage * 12 + index
                    readonly property bool current: yr === Clock.date.getFullYear()
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8
                    color: current ? Theme.yellow
                         : yrMa.containsMouse ? Theme.bg2 : Theme.bg1
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        anchors.centerIn: parent
                        text: parent.yr
                        color: parent.current ? Theme.bg0 : Theme.fg
                        font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
                    }
                    MouseArea {
                        id: yrMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            calPopup.viewYear = parent.yr;
                            calPopup.yearPage = 0;
                            calPopup.mode = "months";
                        }
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
                    calPopup.mode = "days";
                }
            }
        }
    }
}
