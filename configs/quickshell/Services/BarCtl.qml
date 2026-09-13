pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Bar visibility, togglable from outside:  qs ipc call bar toggle
Singleton {
    id: barCtl

    property bool hidden: false

    IpcHandler {
        target: "bar"
        function toggle(): void { barCtl.hidden = !barCtl.hidden }
        function hide(): void { barCtl.hidden = true }
        function show(): void { barCtl.hidden = false }
    }
}
