// Bar.qml — assembles one bar per monitor. No feature logic lives here:
// widgets come from modules/<feature>/, backends from Services/.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "Services"
import "Widgets"
import "modules/workspaces"
import "modules/layouts"
import "modules/media"
import "modules/tray"
import "modules/sysmon"
import "modules/gpu"
import "modules/network"
import "modules/bluetooth"
import "modules/audio"
import "modules/display"
import "modules/battery"
import "modules/notifications"
import "modules/clipboard"
import "modules/calendar"

Scope {
    id: perScreen
    property var modelData

    PanelWindow {
        id: bar
        screen: perScreen.modelData
        anchors { top: true; left: true; right: true }
        implicitHeight: Theme.barHeight
        color: Theme.bg0

        // ---- per-monitor mango state (used by Tags + layout button) ----
        property var mTags: []
        property string mLayoutSym: "?"
        Process {
            id: monWatch
            running: true
            command: ["mmsg", "watch", "monitor", perScreen.modelData.name]
            stdout: SplitParser {
                onRead: data => {
                    try {
                        const j = JSON.parse(data);
                        bar.mTags = j.tags ?? [];
                        bar.mLayoutSym = j.layout_symbol ?? "?";
                    } catch (e) { /* partial line, ignore */ }
                }
            }
            onExited: monRestart.start()
        }
        Timer { id: monRestart; interval: 2000; onTriggered: monWatch.running = true }


        // ---- popup management: one open at a time ----
        readonly property var allPopups: [
            layoutPopup, wifiPopup, btPopup, audioPopup,
            displayPopup, batteryPopup, sysPopup, gpuPopup, notifPopup,
            clipPopup, calPopup, mediaPopup, trayMenuPopup]
        readonly property bool anyPopupOpen:
            layoutPopup.visible || wifiPopup.visible
            || btPopup.visible || audioPopup.visible || displayPopup.visible
            || batteryPopup.visible || sysPopup.visible || gpuPopup.visible
            || notifPopup.visible
            || clipPopup.visible || calPopup.visible || mediaPopup.visible
            || trayMenuPopup.visible
        onAnyPopupOpenChanged: OsdSvc.osdSuppressed = anyPopupOpen
        function closeAllPopups() {
            // defensive: one failed-to-load popup must not brick every click
            for (const o of allPopups) {
                if (o) { try { o.visible = false; } catch (e) {} }
            }
        }
        function togglePopup(p) {
            if (!p) { console.warn("togglePopup: popup failed to load"); return; }
            const wasOpen = p.visible;
            closeAllPopups();
            p.visible = !wasOpen;
        }
        function togglePopupAt(p, item) {
            if (!p || !item) { console.warn("togglePopupAt: missing popup/item"); return; }
            const x = item.mapToItem(null, 0, 0).x;
            p.margins.left = Math.max(8, Math.min(x, bar.width - p.implicitWidth - 8));
            togglePopup(p);
        }

        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 2; color: Theme.bg1 }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8

            // -------- left cluster --------
            Tags { bar: bar }

            BarButton {   // layout -> modules/layouts
                text: bar.mLayoutSym
                fgColor: Theme.green
                tooltip: "layout (click: picker, right: cycle, middle: toggle float)"
                onClicked: bar.togglePopup(layoutPopup)
                onRightClicked: Mango.dispatch("switch_layout")
                onMiddleClicked: Mango.dispatch("togglefloating")
            }

            Item { Layout.fillWidth: true }   // spacer

            // -------- right cluster --------
            SysChip { bar: bar; popup: sysPopup }
            GpuPill { bar: bar; popup: gpuPopup }
            Tray { bar: bar; menuPopup: trayMenuPopup }

            BarButton {   // clipboard -> modules/clipboard
                text: "󰅍"
                px: Theme.iconSize
                fgColor: Theme.fg0
                onClicked: {
                    bar.togglePopup(clipPopup);
                    if (clipPopup.visible) {
                        Clip.refreshClip();
                        clipPopup.focusSearch();
                    }
                }
            }

            MediaPill { bar: bar; popup: mediaPopup }
            AudioPill { bar: bar; popup: audioPopup }
            BtPill { bar: bar; popup: btPopup }
            DisplayPill { bar: bar; popup: displayPopup }
            WifiPill { bar: bar; popup: wifiPopup }
            BatteryPill { bar: bar; popup: batteryPopup }

            BarButton {   // bell -> modules/notifications
                // glyph-only states (DND, empty bell) render at full icon size;
                // the smaller size only existed to fit the count next to the bell
                px: (NotifSvc.doNotDisturb || NotifSvc.notifHistory.count === 0)
                    ? Theme.iconSize : Theme.iconSize - 4
                text: NotifSvc.doNotDisturb ? "󰂛"
                    : (NotifSvc.notifHistory.count > 0 ? "󰂚 " + NotifSvc.notifHistory.count : "󰂜")
                fgColor: NotifSvc.doNotDisturb ? Theme.red
                       : (NotifSvc.notifHistory.count > 0 ? Theme.yellow : Theme.fgDim)
                tooltip: NotifSvc.doNotDisturb ? "do not disturb (right-click to allow)" : "notifications (right-click: DND)"
                onClicked: bar.togglePopup(notifPopup)
                onRightClicked: NotifSvc.doNotDisturb = !NotifSvc.doNotDisturb
            }

            BarButton {   // clock -> modules/calendar
                text: Qt.formatDateTime(Clock.date, "ddd dd MMM  HH:mm")
                fgColor: Theme.fg
                onClicked: bar.togglePopup(calPopup)
            }
        }

        // ---- popups (one file each under modules/) ----
        LayoutPopup { id: layoutPopup; bar: bar }
        WifiPopup { id: wifiPopup; bar: bar }
        BtPopup { id: btPopup; bar: bar }
        AudioPopup { id: audioPopup; bar: bar }
        DisplayPopup { id: displayPopup; bar: bar }
        BatteryPopup { id: batteryPopup; bar: bar }
        SysPopup { id: sysPopup; bar: bar }
        GpuPopup { id: gpuPopup; bar: bar }
        NotifCenter { id: notifPopup; bar: bar }
        ClipPopup { id: clipPopup; bar: bar }
        CalendarPopup { id: calPopup; bar: bar }
        MediaPopup { id: mediaPopup; bar: bar }
        TrayMenu { id: trayMenuPopup; bar: bar }
    }

    // transparent fullscreen catcher: click anywhere outside -> close popups
    PanelWindow {
        screen: perScreen.modelData
        visible: bar.anyPopupOpen
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        anchors { top: true; bottom: true; left: true; right: true }
        margins.top: Theme.barHeight
        color: "transparent"
        MouseArea {
            anchors.fill: parent
            onClicked: bar.closeAllPopups()
        }
    }
}
