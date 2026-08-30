pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: clock

    readonly property date date: sys.date
    SystemClock { id: sys; precision: SystemClock.Minutes }
}
