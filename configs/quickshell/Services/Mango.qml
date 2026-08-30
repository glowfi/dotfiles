pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: mango

    // ================= mango IPC =================
    // mango layouts: config name -> bar glyph (symbol comes from mango itself)
    readonly property var mangoLayouts: [
        { name: "tile",              sym: "T"  },
        { name: "scroller",          sym: "S"  },
        { name: "grid",              sym: "G"  },
        { name: "monocle",           sym: "M"  },
        { name: "deck",              sym: "K"  },
        { name: "center_tile",       sym: "CT" },
        { name: "right_tile",        sym: "RT" },
        { name: "vertical_scroller", sym: "VS" },
        { name: "vertical_tile",     sym: "VT" },
        { name: "vertical_grid",     sym: "VG" },
        { name: "vertical_deck",     sym: "VK" },
        { name: "dwindle",           sym: "DW" },
        { name: "fair",              sym: "F"  },
        { name: "vertical_fair",     sym: "VF" }
    ]

    function dispatch(cmd) {
        // mmsg replies with JSON; surface failures as a toast instead of
        // discarding them (execDetached would swallow the error silently)
        Quickshell.execDetached(["sh", "-c",
            "out=$(mmsg dispatch \"$1\" 2>&1); case \"$out\" in *error*) " +
            "notify-send 'mango dispatch failed' \"$1 -> $out\";; esac",
            "_", cmd]);
    }
}
