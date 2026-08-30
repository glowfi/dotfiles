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
    function copyClip(cid) {
        Quickshell.execDetached(["sh", "-c",
            "printf '%s' '" + cid + "' | cliphist decode | wl-copy"]);
    }
}
