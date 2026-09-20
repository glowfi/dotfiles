pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: theme

    // ================= gruvbox dark =================
    readonly property color bg0:    "#282828"
    readonly property color bg0h:   "#1d2021"
    readonly property color bg1:    "#3c3836"
    readonly property color bg2:    "#504945"
    readonly property color bg3:    "#665c54"
    readonly property color fg0:    "#fbf1c7"
    readonly property color fg:     "#ebdbb2"
    readonly property color fgDim:  "#a89984"
    readonly property color gray:   "#928374"
    readonly property color red:    "#fb4934"
    readonly property color green:  "#b8bb26"
    readonly property color yellow: "#fabd2f"
    readonly property color blue:   "#83a598"
    readonly property color purple: "#d3869b"
    readonly property color aqua:   "#8ec07c"
    readonly property color orange: "#fe8019"

    readonly property string fontFamily: "Fantasque Sans Mono"
    property int fontSize: 17
    readonly property int iconSize: fontSize + 9

    function setFontSize(v) {
        fontSize = Math.max(12, Math.min(24, v));
        Quickshell.execDetached(["sh", "-c",
            'mkdir -p "$HOME/.config/mango" && printf %s "$1" > "$HOME/.config/mango/shell-ui.json"',
            "_", JSON.stringify({ fontSize: fontSize })]);
    }
    Process {
        id: uiLoad
        command: ["sh", "-c", 'cat "$HOME/.config/mango/shell-ui.json" 2>/dev/null || echo "{}"']
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const u = JSON.parse(text.trim() || "{}");
                    if (u.fontSize) fontSize = Math.max(12, Math.min(24, u.fontSize));
                } catch (e) {}
            }
        }
    }
    readonly property int barHeight: 44

    // ================= intuitive level-based icons =================
    function batIcon(pct, charging) {
        if (charging) return "󰂄";
        return pct >= 90 ? "󰁹" : pct >= 70 ? "󰂀" : pct >= 50 ? "󰁾"
             : pct >= 30 ? "󰁼" : pct >= 15 ? "󰁻" : "󰁺";
    }
    function volIcon(vol, muted) {
        if (muted) return "󰖁";
        return vol >= 0.66 ? "󰕾" : vol >= 0.33 ? "󰖀" : "󰕿";
    }
    function wifiIcon(sig) {
        return sig > 75 ? "󰤨" : sig > 50 ? "󰤥" : sig > 25 ? "󰤢" : "󰤟";
    }
}
