import QtQuick
import QtQuick.Controls.impl
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs.theme
import qs.services

Item {
    id: root

    signal clicked

    implicitWidth: visualPill.implicitWidth
    implicitHeight: visualPill.implicitHeight

    readonly property var networkDevices: Networking.devices?.values ?? []
    readonly property var connectedWifiNetwork: {
        for (const dev of networkDevices) {
            if (dev.type !== DeviceType.Wifi) continue;
            const nets = dev.networks?.values ?? [];
            const found = nets.find(n => n.connected);
            if (found)
                return found;
        }
        return null;
    }
    readonly property bool ethernetConnected: networkDevices.some(dev => dev.type === DeviceType.Wired && dev.connected)
    readonly property color networkColor: (connectedWifiNetwork || ethernetConnected) ? Theme.on_surface : Theme.on_surface_variant

    function networkIcon() {
        if (connectedWifiNetwork) {
            const s = connectedWifiNetwork.signalStrength ?? 0;
            if (s >= 0.8) return "signal_wifi_4_bar";
            if (s >= 0.55) return "network_wifi_3_bar";
            if (s >= 0.3) return "network_wifi_2_bar";
            if (s > 0) return "network_wifi_1_bar";
            return "signal_wifi_0_bar";
        }
        if (ethernetConnected) return "lan";
        return "signal_wifi_off";
    }

    readonly property var btAdapter: Bluetooth.defaultAdapter ?? (Bluetooth.adapters?.values?.[0] ?? null)
    readonly property bool btPowered: btAdapter?.enabled ?? false
    readonly property int btConnectedCount: (btAdapter?.devices?.values ?? []).filter(d => d.connected).length
    readonly property color bluetoothColor: !btPowered ? Theme.on_surface_variant : (btConnectedCount > 0 ? Theme.primary : Theme.on_surface)

    function bluetoothIcon() {
        if (!btPowered) return "bluetooth_disabled";
        return btConnectedCount > 0 ? "bluetooth_connected" : "bluetooth";
    }

    readonly property var activeSink: Pipewire.defaultAudioSink
    readonly property bool isMuted: activeSink?.audio?.muted ?? true
    readonly property real volumeLevel: activeSink?.audio?.volume ?? 0.0
    readonly property color volumeColor: isMuted ? Theme.critical : Theme.on_surface

    PwObjectTracker {
        objects: root.activeSink ? [root.activeSink] : []
    }

    function volumeIcon() {
        if (!activeSink?.audio || isMuted) return "volume_off";
        if (volumeLevel >= 0.6) return "volume_up";
        if (volumeLevel >= 0.3) return "volume_down";
        return "volume_mute";
    }

    readonly property var battery: UPower.displayDevice
    readonly property bool batteryPresent: battery?.isLaptopBattery ?? false
    readonly property real batteryPct: (battery?.percentage ?? 0) * 100
    readonly property bool batteryCharging: battery?.state === UPowerDeviceState.Charging || battery?.state === UPowerDeviceState.PendingCharge || battery?.state === UPowerDeviceState.FullyCharged

    readonly property color batteryColor: (batteryPct < 20 && !batteryCharging) ? Theme.critical : Theme.on_surface

    function batteryIcon() {
        const pct = battery?.percentage ?? 0;
        if (pct >= 1)
            return "battery_android_full";
        if (batteryCharging)
            return "battery_android_bolt";
        const level = Math.max(0, Math.min(6, Math.round(pct * 6)));
        return "battery_android_" + level;
    }

    Rectangle {
        id: visualPill
        anchors.centerIn: parent

        implicitWidth: iconsRow.implicitWidth + Layout.s(32)
        implicitHeight: iconsRow.implicitHeight + Layout.s(16)
        radius: height / 2

        color: pillMouse.containsMouse ? Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)) : Theme.surface_container
        scale: pillMouse.pressed ? 0.95 : 1.0

        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        MouseArea {
            id: pillMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }

        Row {
            id: iconsRow
            anchors.centerIn: parent
            spacing: Layout.s(14)

            Text {
                text: root.networkIcon()
                color: root.networkColor
                anchors.verticalCenter: parent.verticalCenter
                font { family: Layout.fontIcons; pixelSize: Layout.s(20) }
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Text {
                text: root.bluetoothIcon()
                color: root.bluetoothColor
                anchors.verticalCenter: parent.verticalCenter
                font { family: "Material Symbols Rounded"; pixelSize: 20 }
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Text {
                text: root.volumeIcon()
                color: root.volumeColor
                anchors.verticalCenter: parent.verticalCenter
                font { family: "Material Symbols Rounded"; pixelSize: 20 }
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Row {
                visible: KbLayout.available
                spacing: Layout.s(6)
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: KbLayout.activeLayout
                    color: Theme.on_surface_variant
                    anchors.verticalCenter: parent.verticalCenter
                    font { family: Layout.fontSans; pixelSize: Layout.ts(12); weight: Font.Medium }
                }

                MouseArea {
                    width: Layout.s(24)
                    height: parent.height
                    cursorShape: Qt.PointingHandCursor
                    onClicked: KbLayout.cycle()
                }
            }

            Item {
                id: batteryWidget
                visible: root.batteryPresent
                implicitWidth: Layout.s(30)
                implicitHeight: Layout.s(22)
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: batteryGlyph
                    anchors.centerIn: parent
                    text: root.batteryIcon()
                    color: root.batteryColor
                    font { family: "Material Symbols Rounded"; pixelSize: Layout.s(30) }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Text {
                    id: batteryPercent
                    anchors.centerIn: batteryGlyph
                    anchors.horizontalCenterOffset: -Math.round(batteryGlyph.implicitWidth * 0.055)
                    visible: !(root.batteryCharging && root.batteryPct < 100)
                    text: Math.round(root.batteryPct)
                    color: root.batteryPct >= 50 ? Theme.surface_container : root.batteryColor
                    font { family: Layout.fontSans; pixelSize: Layout.s(11); weight: Font.Bold }
                }
            }
        }
    }
}
