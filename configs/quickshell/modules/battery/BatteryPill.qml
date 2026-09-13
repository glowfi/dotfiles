import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Services"
import "../../Widgets"
import Quickshell.Services.UPower

StatusPill {
    required property var bar
    required property var popup
    id: batteryPill
    readonly property var bat: UPower.displayDevice
    readonly property bool charging: bat && bat.state === UPowerDeviceState.Charging
    visible: bat !== null && bat.isLaptopBattery
    icon: bat ? Theme.batIcon(bat.percentage * 100, charging) : "󰁹"
    iconColor: charging ? Theme.aqua
             : (bat && bat.percentage < 0.2 ? Theme.red : Theme.green)
    // current power profile at a glance
    readonly property string profLabel:
        PowerProfiles.profile === PowerProfile.PowerSaver ? "saver"
        : PowerProfiles.profile === PowerProfile.Performance ? "perf" : "bal"
    value: (bat ? Math.round(bat.percentage * 100) + "%" : "") + " · " + profLabel
    tooltip: {
        const p = PowerProfiles.profile === PowerProfile.PowerSaver ? "power saver"
                : PowerProfiles.profile === PowerProfile.Performance ? "performance" : "balanced";
        return "battery — profile: " + p;
    }
    onClicked: bar.togglePopupAt(popup, batteryPill)
}
