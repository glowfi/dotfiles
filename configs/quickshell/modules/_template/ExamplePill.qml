// Template bar widget. Conventions:
//   - `bar`   : the PanelWindow (popup manager lives on it)
//   - `popup` : this feature's popup instance (wired in Bar.qml)
// Read state from a Services/ singleton, never poll here.
import QtQuick
import "../../Services"
import "../../Widgets"

StatusPill {
    id: examplePill
    required property var bar
    required property var popup

    icon: "󰋗"
    iconColor: Theme.fg0
    value: "example"
    tooltip: "example module"
    onClicked: bar.togglePopupAt(popup, examplePill)
}
