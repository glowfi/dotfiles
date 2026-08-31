import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../Services"
import "../../Widgets"
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    required property var bar
    // ---- output state via wlr-output-management (wlr-randr) ----
    property string dispTarget: bar.screen.name
    property var outModes: []
    property real outScale: 1
    property bool outEnabled: true
    property string outTransform: "normal"
    property var outAll: []          // every output: name, x, y, logical w/h, enabled
    Process {
        id: dispInfo
        command: ["wlr-randr", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const outs = JSON.parse(text);
                    const all = [];
                    for (const o of outs) {
                        const cm = (o.modes ?? []).find(m => m.current)
                                ?? (o.modes ?? []).find(m => m.preferred)
                                ?? (o.modes ?? [])[0] ?? { width: 0, height: 0 };
                        const sc = o.scale ?? 1;
                        const rot = String(o.transform ?? "normal");
                        const swap = rot === "90" || rot === "270"
                                  || rot === "flipped-90" || rot === "flipped-270";
                        all.push({
                            name: o.name,
                            x: o.position ? o.position.x : 0,
                            y: o.position ? o.position.y : 0,
                            w: Math.round((swap ? cm.height : cm.width) / sc),
                            h: Math.round((swap ? cm.width : cm.height) / sc),
                            enabled: o.enabled !== false
                        });
                    }
                    outAll = all;

                    const me = outs.find(o => o.name === dispTarget);
                    if (!me) return;
                    outScale = me.scale ?? 1;
                    outEnabled = me.enabled !== false;
                    outTransform = String(me.transform ?? "normal");
                    const seen = {};
                    const modes = [];
                    for (const m of (me.modes ?? [])) {
                        const key = m.width + "x" + m.height + "@" + Math.round(m.refresh);
                        if (seen[key]) { if (m.current) seen[key].current = true; continue; }
                        const e = { w: m.width, h: m.height, refresh: m.refresh,
                                    current: m.current === true };
                        seen[key] = e;
                        modes.push(e);
                    }
                    modes.sort((a, b) => (b.w * b.h - a.w * a.h) || (b.refresh - a.refresh));
                    outModes = modes;
                } catch (e) { outModes = []; }
            }
        }
    }
    Timer { id: dispRefresh; interval: 800; onTriggered: dispInfo.running = true }
    function applyMode(m) {
        Quickshell.execDetached(["wlr-randr", "--output", dispTarget,
            "--mode", m.w + "x" + m.h + "@" + m.refresh.toFixed(3)]);
        DisplayCtl.persistDisplay(dispTarget, { mode: m.w + "x" + m.h + "@" + m.refresh.toFixed(3) });
        dispRefresh.restart();
    }
    function applyScale(v) {
        Quickshell.execDetached(["wlr-randr", "--output", dispTarget, "--scale", String(v)]);
        DisplayCtl.persistDisplay(dispTarget, { scale: v });
        dispRefresh.restart();
    }
    function applyTransform(t) {
        Quickshell.execDetached(["wlr-randr", "--output", dispTarget, "--transform", t]);
        DisplayCtl.persistDisplay(dispTarget, { transform: t });
        dispRefresh.restart();
    }
    function applyEnabled(on) {
        Quickshell.execDetached(["wlr-randr", "--output", dispTarget, on ? "--on" : "--off"]);
        DisplayCtl.persistDisplay(dispTarget, { on: on });
        dispRefresh.restart();
    }
    function placeRelative(dir, refName) {
        const t = outAll.find(o => o.name === dispTarget);
        const r = outAll.find(o => o.name === refName);
        if (!t || !r) return;
        let x = r.x, y = r.y;
        if (dir === "left")  { x = r.x - t.w; y = r.y; }
        if (dir === "right") { x = r.x + r.w; y = r.y; }
        if (dir === "above") { x = r.x; y = r.y - t.h; }
        if (dir === "below") { x = r.x; y = r.y + r.h; }
        if (dir === "mirror"){ x = r.x; y = r.y; }
        Quickshell.execDetached(["wlr-randr", "--output", dispTarget, "--pos", x + "," + y]);
        DisplayCtl.persistDisplay(dispTarget, { pos: x + "," + y });
        dispRefresh.restart();
    }

    id: displayPopup
    screen: bar.screen
    property bool resOpen: false
    property string posRef: {
        const other = outAll.find(o => o.name !== dispTarget);
        return other ? other.name : "";
    }
    onVisibleChanged: if (visible) {
        dispTarget = bar.screen.name;
        resOpen = false;
        dispInfo.running = true;
    }
    anchors { top: true; left: true }
    margins { top: Theme.barHeight + 4; left: 8 }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    implicitWidth: 300
    implicitHeight: dispCol.implicitHeight + 28
    visible: false
    color: Theme.bg0h

    ColumnLayout {
        id: dispCol
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        spacing: 10

        SectionLabel { text: "BRIGHTNESS" }
        RowLayout {
            spacing: 8
            visible: DisplayCtl.brightness >= 0
            Text {
                text: "󰃞"
                color: Theme.fg0
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.iconSize }
            }
            GruvSlider {
                Layout.fillWidth: true
                value: Math.max(0, DisplayCtl.brightness) / 100
                onMoved: v => DisplayCtl.setBrightness(v * 100)
            }
            Text {
                text: DisplayCtl.brightness + "%"
                color: Theme.fgDim
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
                Layout.preferredWidth: 52
            }
        }
        Text {
            visible: DisplayCtl.brightness < 0
            text: "no controllable backlight"
            color: Theme.gray
            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 2 }
        }

        SectionLabel { text: "NIGHT LIGHT" }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                text: DisplayCtl.nightLight ? "󰛨" : "󰹏"
                color: DisplayCtl.nightLight ? Theme.orange : Theme.fgDim
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.iconSize }
            }
            Text {
                Layout.fillWidth: true
                text: DisplayCtl.nightLight ? "on — 4000K warm tint" : "off — normal colors"
                color: Theme.fg
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
            }
            TogglePill {
                on: DisplayCtl.nightLight
                onClicked: DisplayCtl.toggleNightLight()
            }
        }

        SectionLabel { text: "FONT SIZE  (shell)" }
        RowLayout {
            spacing: 8
            ActionChip {
                label: "A−"
                enabled: Theme.fontSize > 12
                onClicked: Theme.setFontSize(Theme.fontSize - 1)
            }
            Text {
                Layout.fillWidth: true
                text: Theme.fontSize + " px"
                horizontalAlignment: Text.AlignHCenter
                color: Theme.fg
                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
            }
            ActionChip {
                label: "A+"
                enabled: Theme.fontSize < 24
                onClicked: Theme.setFontSize(Theme.fontSize + 1)
            }
        }

        SectionLabel {
            text: "MONITOR"
            visible: Quickshell.screens.length > 1
        }
        RowLayout {
            spacing: 6
            visible: Quickshell.screens.length > 1
            Repeater {
                model: Quickshell.screens
                ActionChip {
                    required property var modelData
                    label: modelData.name
                    accent: dispTarget === modelData.name
                    Layout.fillWidth: true
                    onClicked: {
                        dispTarget = modelData.name;
                        displayPopup.resOpen = false;
                        dispInfo.running = true;
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            SectionLabel {
                Layout.fillWidth: true
                text: "OUTPUT  (" + dispTarget + ")"
            }
            TogglePill {
                // don't allow blacking out the last enabled monitor
                enabled: !outEnabled
                         || outAll.filter(o => o.enabled).length > 1
                opacity: enabled ? 1 : 0.45
                on: outEnabled
                onClicked: applyEnabled(!outEnabled)
            }
        }

        SectionLabel { text: "SCALE  (" + outScale.toFixed(2) + "×)" }
        RowLayout {
            spacing: 6
            Repeater {
                model: ["1", "1.25", "1.5", "1.75", "2"]
                ActionChip {
                    required property var modelData
                    label: modelData + "×"
                    accent: Math.abs(outScale - parseFloat(modelData)) < 0.01
                    Layout.fillWidth: true
                    onClicked: applyScale(parseFloat(modelData))
                }
            }
        }

        SectionLabel { text: "RESOLUTION" }
        // collapsed dropdown: current mode; click to expand the list
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 36
            radius: 5
            color: resHead.containsMouse ? Theme.bg2 : Theme.bg1
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                Text {
                    Layout.fillWidth: true
                    text: {
                        const c = outModes.find(m => m.current);
                        return c ? c.w + "×" + c.h + "  @ " + Math.round(c.refresh) + "Hz"
                                 : (outModes.length ? "select mode" : "wlr-randr not available");
                    }
                    color: Theme.fg
                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
                }
                Text {
                    text: displayPopup.resOpen ? "▴" : "▾"
                    color: Theme.fgDim
                    font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
                }
            }
            MouseArea {
                id: resHead
                anchors.fill: parent
                hoverEnabled: true
                onClicked: displayPopup.resOpen = !displayPopup.resOpen
            }
        }
        Flickable {
            id: modeFlick
            visible: displayPopup.resOpen
            contentWidth: width
            flickableDirection: Flickable.VerticalFlick
            Layout.fillWidth: true
            implicitHeight: Math.min(170, modeCol.implicitHeight)
            contentHeight: modeCol.implicitHeight
            clip: true
            ScrollBar.vertical: GruvScrollBar {}
            ColumnLayout {
                id: modeCol
                width: modeFlick.width - 14
                spacing: 2
                Repeater {
                    model: outModes
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 32
                        radius: 5
                        color: modelData.current ? Theme.bg2
                             : (modeMa.containsMouse ? Theme.bg1 : "transparent")
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            Text {
                                Layout.fillWidth: true
                                text: modelData.w + "×" + modelData.h
                                      + "  @ " + Math.round(modelData.refresh) + "Hz"
                                color: modelData.current ? Theme.fg0 : Theme.fg
                                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 2 }
                            }
                            Text {
                                visible: modelData.current
                                text: "󰄬"
                                color: Theme.green
                                font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize - 1 }
                            }
                        }
                        MouseArea {
                            id: modeMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                applyMode(modelData);
                                displayPopup.resOpen = false;
                            }
                        }
                    }
                }
            }
        }

        SectionLabel { text: "ROTATION" }
        RowLayout {
            spacing: 6
            Repeater {
                model: [
                    { t: "normal", label: "0°" },
                    { t: "90",     label: "90°" },
                    { t: "180",    label: "180°" },
                    { t: "270",    label: "270°" }
                ]
                ActionChip {
                    required property var modelData
                    label: modelData.label
                    accent: outTransform === modelData.t
                    Layout.fillWidth: true
                    onClicked: applyTransform(modelData.t)
                }
            }
        }

        // position relative to another output (multi-monitor only)
        SectionLabel {
            text: "POSITION  (relative to " + displayPopup.posRef + ")"
            visible: Quickshell.screens.length > 1
        }
        RowLayout {
            spacing: 6
            visible: Quickshell.screens.length > 1
                     && outAll.filter(o => o.name !== dispTarget).length > 1
            Repeater {
                model: outAll.filter(o => o.name !== dispTarget)
                ActionChip {
                    required property var modelData
                    label: modelData.name
                    accent: displayPopup.posRef === modelData.name
                    Layout.fillWidth: true
                    onClicked: displayPopup.posRef = modelData.name
                }
            }
        }
        RowLayout {
            spacing: 6
            visible: Quickshell.screens.length > 1
            Repeater {
                model: [
                    { d: "left",   label: "󰜱 left of" },
                    { d: "right",  label: "󰜴 right of" },
                    { d: "above",  label: "󰜷 above" },
                    { d: "below",  label: "󰜮 below" },
                    { d: "mirror", label: "󰍺 mirror" }
                ]
                ActionChip {
                    required property var modelData
                    label: modelData.label
                    Layout.fillWidth: true
                    onClicked: placeRelative(modelData.d, displayPopup.posRef)
                }
            }
        }
    }
}
