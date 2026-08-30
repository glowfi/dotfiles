pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: notifSvc

    property bool doNotDisturb: false

    // exposed as properties: ids are file-private, so a bare
    // `ListModel { id: ... }` would be invisible to other modules
    readonly property alias notifHistory: histModel
    readonly property alias notifServer: serverObj

    ListModel { id: histModel }

    NotificationServer {
        id: serverObj
        onNotification: n => {
            n.tracked = true;
            histModel.insert(0, {
                nApp: n.appName || "notification",
                nSummary: n.summary || "",
                nBody: n.body || "",
                nTime: Qt.formatTime(new Date(), "HH:mm")
            });
            if (histModel.count > 50) histModel.remove(50, histModel.count - 50);
        }
    }
}
