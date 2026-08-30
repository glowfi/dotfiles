pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: notifSvc

    property bool doNotDisturb: false

    ListModel { id: notifHistory }

    NotificationServer {
        id: notifServer
        onNotification: n => {
            n.tracked = true;
            notifHistory.insert(0, {
                nApp: n.appName || "notification",
                nSummary: n.summary || "",
                nBody: n.body || "",
                nTime: Qt.formatTime(new Date(), "HH:mm")
            });
            if (notifHistory.count > 50) notifHistory.remove(50, notifHistory.count - 50);
        }
    }
}
