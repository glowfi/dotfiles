import QtQuick
import "../../Services"
import "../../Widgets"

StatusPill {
    id: gpuPill
    required property var bar
    required property var popup

    visible: Gpu.gpus.length > 0
    icon: "󰢮"
    iconColor: Theme.fg0
    value: {
        const g = Gpu.sel;
        if (!g) return "";
        return (g.busy >= 0 ? g.busy + "%" : "--")
             + (Gpu.gpus.length > 1 ? " · " + Gpu.vendorName(g.vendor) : "");
    }
    tooltip: "gpu — click for details" + (Gpu.gpus.length > 1 ? " & switching" : "")
    onClicked: bar.togglePopupAt(popup, gpuPill)
}
