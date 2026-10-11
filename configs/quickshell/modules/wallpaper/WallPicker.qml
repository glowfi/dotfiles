// Fullscreen wallpaper picker — "lightbox" design: one LARGE centered
// preview (judge the wallpaper at size, not as a sliver), crossfading as
// you navigate, with a flat thumbnail rail for jumping.
// Toggle:  qs ipc call wallpicker toggle   (bind: SUPER+w)
// Keys: ←/→ navigate · Enter apply · Esc close. Wheel on preview navigates.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../Services"

PanelWindow {
    id: wallPicker
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    visible: false
    color: "#cc000000"

    // selection is the PATH itself — the clicked thumb's own string flows
    // straight to apply(), so clicked-vs-applied mismatch is impossible by
    // construction (no index hops that array updates could desync)
    property string selPath: ""
    readonly property int sel: Wallpaper.walls.indexOf(selPath)
    readonly property string current: selPath

    IpcHandler {
        target: "wallpicker"
        function toggle(): void { wallPicker.visible = !wallPicker.visible }
        function show(): void { wallPicker.visible = true }
        function hide(): void { wallPicker.visible = false }
    }

    onVisibleChanged: if (visible) {
        Wallpaper.rescan();
        selPath = Wallpaper.walls.length > 0 ? Wallpaper.walls[0] : "";
        pickerFocus.forceActiveFocus();
    }
    onCurrentChanged: if (current !== "") crossfade.swap(current)

    function move(step) {
        const n = Wallpaper.walls.length;
        if (n === 0) return;
        const i = Math.max(0, Wallpaper.walls.indexOf(selPath));
        selPath = Wallpaper.walls[((i + step) % n + n) % n];
    }
    function apply() {
        if (current === "") return;
        Wallpaper.set(current);
        visible = false;
    }

    Connections {
        target: Wallpaper
        function onWallsChanged() {
            if (wallPicker.visible && Wallpaper.walls.indexOf(wallPicker.selPath) === -1)
                wallPicker.selPath = Wallpaper.walls.length > 0 ? Wallpaper.walls[0] : "";
        }
    }

    MouseArea { anchors.fill: parent; onClicked: wallPicker.visible = false }

    Item {
        id: pickerFocus
        anchors.fill: parent
        Keys.onPressed: ev => {
            if (ev.key === Qt.Key_Escape) { wallPicker.visible = false; ev.accepted = true; }
            else if (ev.key === Qt.Key_Left) { wallPicker.move(-1); ev.accepted = true; }
            else if (ev.key === Qt.Key_Right) { wallPicker.move(1); ev.accepted = true; }
            else if (ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) {
                wallPicker.apply(); ev.accepted = true;
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 16

        // ---- the preview: two stacked images, crossfading on swap ----
        Rectangle {
            id: previewFrame
            width: Math.min(wallPicker.width * 0.68, 1300)
            height: Math.min(wallPicker.height * 0.62, 760)
            anchors.horizontalCenter: parent.horizontalCenter
            radius: 10
            color: Theme.bg0h
            border.width: 1
            border.color: Theme.bg2
            clip: true

            Item {
                id: crossfade
                anchors.fill: parent
                anchors.margins: 1
                property bool aFront: true
                function swap(src) {
                    // load into the buffer that becomes VISIBLE after the
                    // flip. The inverted pick here made the preview show the
                    // PREVIOUS selection — one step behind the thumbnails.
                    const incoming = aFront ? imgA : imgB;
                    incoming.source = Wallpaper.toUrl(src);
                    aFront = !aFront;
                }
                Image {
                    id: imgA
                    anchors.fill: parent
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    opacity: crossfade.aFront ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                }
                Image {
                    id: imgB
                    anchors.fill: parent
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    opacity: crossfade.aFront ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                }
            }

            MouseArea {   // wheel navigates, click applies
                anchors.fill: parent
                onWheel: ev => wallPicker.move(ev.angleDelta.y < 0 ? 1 : -1)
                onClicked: wallPicker.apply()
            }
        }

        // ---- caption ----
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Wallpaper.walls.length === 0
                  ? "no wallpapers in " + Wallpaper.wallDir
                  : wallPicker.current.split("/").pop()
                    + "   ·   " + (wallPicker.sel + 1) + "/" + Wallpaper.walls.length
                    + "   ·   enter to apply"
            color: Theme.fg
            font { family: Theme.fontFamily; bold: true; pixelSize: Theme.fontSize }
        }

        // ---- thumbnail rail ----
        Flickable {
            id: rail
            width: Math.min(railRow.width, wallPicker.width - 160)
            height: 64
            anchors.horizontalCenter: parent.horizontalCenter
            contentWidth: railRow.width
            contentHeight: height
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            // keep the selected thumb in view as you arrow
            function ensureVisible() {
                const x = wallPicker.sel * (96 + 8);
                if (x < contentX) contentX = x;
                else if (x + 96 > contentX + width) contentX = x + 96 - width;
            }
            Connections {
                target: wallPicker
                function onSelChanged() { rail.ensureVisible() }
            }

            Row {
                id: railRow
                spacing: 8
                Repeater {
                    model: Wallpaper.walls
                    Rectangle {
                        required property string modelData
                        required property int index
                        width: 96
                        height: 64
                        radius: 5
                        clip: true
                        color: Theme.bg1
                        border.width: wallPicker.sel === index ? 2 : 0
                        border.color: Theme.yellow
                        Image {
                            anchors.fill: parent
                            anchors.margins: parent.border.width
                            asynchronous: true
                            sourceSize.width: 200
                            fillMode: Image.PreserveAspectCrop
                            source: Wallpaper.toUrl(parent.modelData)
                            opacity: wallPicker.sel === parent.index ? 1 : 0.55
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: wallPicker.selPath = parent.modelData
                            onDoubleClicked: {
                                wallPicker.selPath = parent.modelData;
                                Wallpaper.set(parent.modelData);   // apply EXACTLY this thumb
                                wallPicker.visible = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
