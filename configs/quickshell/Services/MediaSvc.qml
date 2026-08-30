pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: mediaSvc

    // ================= media (MPRIS) =================
    readonly property var mprisPlayers: Mpris.players ? Mpris.players.values : []
    readonly property var activePlayer: {
        for (const p of mprisPlayers) if (p.isPlaying) return p;
        return mprisPlayers.length > 0 ? mprisPlayers[0] : null;
    }
    readonly property bool hasMedia: activePlayer !== null
        && ((activePlayer.trackTitle ?? "") !== "" || (activePlayer.trackArtist ?? "") !== "")
}
