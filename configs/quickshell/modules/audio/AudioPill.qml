import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Services"
import "../../Widgets"
import Quickshell.Services.Pipewire

StatusPill {
    required property var bar
    required property var popup
    id: audioPill
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    icon: sink && sink.audio ? Theme.volIcon(sink.audio.volume, sink.audio.muted) : "󰕿"
    iconColor: sink && sink.audio && sink.audio.muted ? Theme.gray : Theme.fg0
    value: sink && sink.audio
           ? (sink.audio.muted ? "mute" : Math.round(sink.audio.volume * 100) + "%")
           : "--"
    tooltip: "audio — scroll: volume, right-click: mute"
    onClicked: bar.togglePopupAt(popup, audioPill)
    onRightClicked: if (sink && sink.audio) sink.audio.muted = !sink.audio.muted
    onWheelMoved: d => {
        if (sink && sink.audio)
            sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + (d > 0 ? 0.05 : -0.05)));
    }
}
