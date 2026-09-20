pragma Singleton
import QtQuick
import Quickshell

// Tooltip state. Widgets compute position/screen THEMSELVES (attached
// properties like Window are only valid in the owning item's scope — reading
// item.Window.window from here silently yields undefined, which is exactly
// the bug that killed v1 of this service) and pass plain values.
Singleton {
    id: tipSvc

    property bool shown: false
    property string text: ""
    property real cx: 0
    property string screenName: ""

    function show(t, x, sname) {
        if (!t || t === "") return;
        text = t;
        cx = x;
        screenName = sname ?? "";
        shown = true;
    }
    function hide() { shown = false }
}
