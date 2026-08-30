pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: rec


    // screen recording detector (wf-recorder / gpu-screen-recorder / wl-screenrec)
    // NOTE: -x (exact process name) — `pgrep -f` would match this very
    // command's own cmdline and report recording forever.
    property bool recActive: false
    // (kernel comm names are truncated to 15 chars, so match the truncation)
    readonly property var recProcs: ["wf-recorder", "gpu-screen-recorder", "wl-screenrec"]
        .map(p => p.substring(0, 15))
    Process {
        id: recCheck
        command: ["sh", "-c",
            "{ " + rec.recProcs.map(p => "pgrep -x " + p + " >/dev/null").join(" || ")
            + "; } && echo on || echo off"]
        running: true
        stdout: StdioCollector { onStreamFinished: recActive = text.trim() === "on" }
    }
    function stopRecording() {
        Quickshell.execDetached(["sh", "-c",
            rec.recProcs.map(p => "pkill -INT -x " + p).join("; ")]);
        recRecheck.start();
    }
    Timer { id: recRecheck; interval: 600; onTriggered: recCheck.running = true }


    Timer { interval: 10000; running: true; repeat: true; onTriggered: recCheck.running = true }
}
