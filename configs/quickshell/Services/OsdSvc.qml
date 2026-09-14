pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: osdSvc

    // Volume changes show NO shell OSD (an external OSD tool owns that).
    // Brightness keys call the IPC below to show the brightness OSD:
    //   qs ipc call osd brightnessUp
    property string osdKind: "volume"
    property bool osdShown: false
    property bool osdSuppressed: false     // no OSD while quick settings is open
    property bool osdReady: false          // no OSD storm during startup
    Timer { interval: 2000; running: true; onTriggered: osdReady = true }
    Timer { id: osdHide; interval: 1600; onTriggered: osdShown = false }
    function showOsd(kind) {
        if (!osdReady || osdSuppressed) return;
        osdKind = kind;
        osdShown = true;
        osdHide.restart();
    }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }


    IpcHandler {
        target: "osd"
        function volumeUp(): void {
            const a = Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null;
            if (a) { a.muted = false; a.volume = Math.min(1.5, a.volume + 0.05); }
        }
        function volumeDown(): void {
            const a = Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null;
            if (a) a.volume = Math.max(0, a.volume - 0.05);
        }
        function mute(): void {
            const a = Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null;
            if (a) a.muted = !a.muted;
        }
        function micMute(): void {
            const a = Pipewire.defaultAudioSource ? Pipewire.defaultAudioSource.audio : null;
            if (a) a.muted = !a.muted;
        }
        function brightnessUp(): void {
            DisplayCtl.setBrightness((DisplayCtl.brightness < 0 ? 50 : DisplayCtl.brightness) + 5);
            showOsd("brightness");
        }
        function brightnessDown(): void {
            DisplayCtl.setBrightness((DisplayCtl.brightness < 0 ? 50 : DisplayCtl.brightness) - 5);
            showOsd("brightness");
        }
    }
}
