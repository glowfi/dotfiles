//@ pragma IconTheme Papirus-Dark
// Modular gruvbox shell for MangoWM. Map:
//   Services/<Feature>.qml   one singleton per backend (state + processes)
//   Widgets/                 dumb reusable primitives (no feature logic)
//   modules/<feature>/       the feature's bar widget(s) + popup(s)
//   Bar.qml                  assembles one bar per monitor
//   shell.qml                this file: bars + global windows (toasts, OSD)
// To add a feature: copy modules/_template, wire it in Bar.qml. See its README.

import Quickshell
import "modules/notifications"
import "modules/osd"

ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar {}
    }

    Toasts {}
    OsdWindow {}
}
