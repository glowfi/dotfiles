pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Wallpaper backend for awww (swww successor). Daemon must be running:
//   exec-once=awww-daemon        (in mango config.conf)
// awww restores the last wallpaper per output on daemon start by itself,
// so there is no persistence code here on purpose.
Singleton {
    id: wallpaper

    // knobs — change these, not the code
    property string bin: "awww"
    property string wallDir: Quickshell.env("HOME") + "/wall"
    property string transition: "grow"
    property real duration: 1.0
    property int fps: 60

    property var walls: []

    function rescan() { scanProc.running = true }

    function set(path) {
        Quickshell.execDetached([bin, "img", path,
            "--transition-type", transition,
            "--transition-pos", "center",
            "--transition-duration", String(duration),
            "--transition-fps", String(fps)]);
    }

    Process {
        id: scanProc
        command: ["sh", "-c",
            'find "' + wallpaper.wallDir + '" -maxdepth 2 -type f ' +
            '\\( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" ' +
            '-o -iname "*.webp" -o -iname "*.gif" \\) 2>/dev/null | sort']
        running: true
        stdout: StdioCollector {
            onStreamFinished: wallpaper.walls = text.trim() === "" ? [] : text.trim().split("\n")
        }
    }
}
