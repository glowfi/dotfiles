pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: net

    // ================= network (nmcli backend) =================
    property string netIface: ""
    property string netSsid: ""
    property int netSignal: 0
    property bool wifiEnabled: true
    property var wifiNets: []          // { inUse, signal, security, ssid }
    property bool wifiScanning: false
    property string wifiError: ""
    property string wifiPwSsid: ""     // ssid currently asking for a password
    property string wifiBusySsid: ""   // ssid with a connection attempt in flight
    property var savedProfiles: []     // wifi connection profiles NM already knows

    function isSaved(ssid) { return savedProfiles.indexOf(ssid) !== -1 }

    Process {
        id: savedCheck
        command: ["sh", "-c",
            "nmcli -t -e no -f NAME,TYPE connection show 2>/dev/null | " +
            "awk -F: '$2 ~ /wireless/ { print $1 }'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: savedProfiles = text.trim() === "" ? [] : text.trim().split("\n")
        }
    }

    function disconnectWifi(ssid) {
        // device-level disconnect; failures surface as notifications instead
        // of vanishing into execDetached
        Quickshell.execDetached(["sh", "-c",
            "dev=$(nmcli -t -e no -f DEVICE,TYPE device status 2>/dev/null" +
            " | grep \":wifi$\" | head -1 | cut -d: -f1);" +
            " if [ -z \"$dev\" ]; then notify-send \"wifi\" \"no wifi device found\"; exit 1; fi;" +
            " out=$(nmcli device disconnect \"$dev\" 2>&1)" +
            " || notify-send \"wifi disconnect failed\" \"$out\""]);
        forgetRefresh.restart();
    }
    function forgetWifi(ssid) {
        Quickshell.execDetached(["nmcli", "connection", "delete", "id", ssid]);
        forgetRefresh.restart();
    }
    Timer {
        id: forgetRefresh; interval: 700
        onTriggered: { savedCheck.running = true; netRecheck.start(); wifiScan.running = true }
    }
    Timer {   // errors don't linger after being read
        id: errClear; interval: 8000
        onTriggered: wifiError = ""
    }
    onWifiErrorChanged: if (wifiError !== "") errClear.restart()

    Process {
        id: netCheck
        command: ["sh", "-c", "ip -o route get 1.1.1.1 2>/dev/null | awk '{print $5; exit}'"]
        running: true
        stdout: StdioCollector { onStreamFinished: netIface = text.trim() }
    }
    Process {
        id: ssidCheck
        command: ["sh", "-c", "nmcli -e no -t -f active,ssid,signal dev wifi 2>/dev/null | sed -n 's/^yes://p' | head -1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim();
                const i = line.lastIndexOf(":");
                if (i < 0) { netSsid = line; netSignal = 0; return; }
                netSsid = line.substring(0, i);
                netSignal = parseInt(line.substring(i + 1)) || 0;
            }
        }
    }
    Process {
        id: radioCheck
        command: ["sh", "-c", "nmcli -t radio wifi 2>/dev/null"]
        running: true
        stdout: StdioCollector { onStreamFinished: wifiEnabled = text.trim() === "enabled" }
    }
    function toggleWifi() {
        Quickshell.execDetached(["sh", "-c",
            "nmcli radio wifi | grep -q enabled && nmcli radio wifi off || nmcli radio wifi on"]);
        netRecheck.start();
    }
    Timer { id: netRecheck; interval: 800; onTriggered: { radioCheck.running = true; netCheck.running = true; ssidCheck.running = true } }

    function scanWifi() {
        wifiError = "";
        wifiScanning = true;
        wifiScan.running = true;
        savedCheck.running = true;
    }
    Process {
        id: wifiScan
        command: ["nmcli", "-t", "-e", "no", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "dev", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const nets = [];
                const seen = {};
                for (const line of text.split("\n")) {
                    const p = line.split(":");
                    if (p.length < 4) continue;
                    const ssid = p.slice(3).join(":").trim();
                    if (ssid === "" || seen[ssid]) continue;
                    seen[ssid] = true;
                    nets.push({
                        inUse: p[0].trim() === "*",
                        signal: parseInt(p[1]) || 0,
                        security: p[2].trim(),
                        ssid: ssid
                    });
                }
                nets.sort((a, b) => (b.inUse - a.inUse) || (b.signal - a.signal));
                wifiNets = nets;
            }
        }
        onExited: wifiScanning = false
    }
    Process {
        id: wifiConn
        property string ssid: ""
        property string pw: ""
        command: pw === "" ? ["nmcli", "dev", "wifi", "connect", ssid]
                           : ["nmcli", "dev", "wifi", "connect", ssid, "password", pw]
        stderr: StdioCollector { onStreamFinished: wifiError = text.trim() }
        onExited: exitCode => {
            wifiBusySsid = "";
            if (exitCode !== 0) {
                wifiPwSsid = wifiConn.ssid;   // likely needs a (correct) password
            } else {
                wifiPwSsid = "";
                wifiError = "";
            }
            netRecheck.start();
            savedCheck.running = true;
            wifiScan.running = true;
        }
    }
    function connectWifi(ssid, pw) {
        wifiError = "";
        wifiBusySsid = ssid;
        wifiConn.ssid = ssid;
        wifiConn.pw = pw;
        wifiConn.running = true;
    }


    Timer {
        interval: 10000; running: true; repeat: true
        onTriggered: { netCheck.running = true; radioCheck.running = true; ssidCheck.running = true }
    }
}
