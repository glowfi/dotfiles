pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: clip

    // ================= clipboard (cliphist backend) =================
    property var clipEntries: []       // { cid, preview }
    Process {
        id: clipList
        command: ["cliphist", "list"]
        running: true   // load persisted history at startup — the bar icon's
                        // visibility depends on it being populated immediately
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab < 1) continue;
                    out.push({ cid: line.substring(0, tab), preview: line.substring(tab + 1) });
                }
                clipEntries = out;
            }
        }
    }
    function refreshClip() { clipList.running = true }

    // keep entries current even while the popup is closed, so the bar icon's
    // auto-hide (visible only when history is non-empty) tracks reality
    Timer { interval: 15000; running: true; repeat: true; onTriggered: clip.refreshClip() }
    Timer { id: clipReQuery; interval: 400; onTriggered: clip.refreshClip() }

    function deleteClip(cid) {
        // cliphist deletes by full original line; reconstruct it by id
        Quickshell.execDetached(["sh", "-c",
            "cliphist list | awk -F. -v OFS=. 'BEGIN { FS = \"\\t\" } $1 == id' id=\"$1\" | cliphist delete",
            "_", cid]);
        clipReQuery.restart();
    }
    function wipeClip() {
        Quickshell.execDetached(["cliphist", "wipe"]);
        clipReQuery.restart();
    }
    function copyClip(cid) {
        Quickshell.execDetached(["sh", "-c",
            "printf '%s' '" + cid + "' | cliphist decode | wl-copy"]);
    }
}
