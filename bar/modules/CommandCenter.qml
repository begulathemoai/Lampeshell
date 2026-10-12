import QtQuick
import QtQuick.Controls.impl
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs.theme

Item {
    id: root

    // The pill emits `clicked`; TopBar forwards it to QuickSettings.toggle().
    // Nothing handled this signal in the upstream config, which is why the
    // status pill looked inert.
    signal clicked

    implicitWidth: visualPill.implicitWidth
    implicitHeight: visualPill.implicitHeight

    // --- Network ---
    readonly property var networkDevices: Networking.devices?.values ?? []
    readonly property var connectedWifiNetwork: {
        for (const dev of networkDevices) {
            const nets = dev.networks?.values ?? [];
            const found = nets.find(n => n.connected);
            if (found)
                return found;
        }
        return null;
    }
    readonly property bool ethernetConnected: networkDevices.some(dev => dev.networks === undefined && dev.connected)
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

    // --- Bluetooth ---
    readonly property var btAdapter: Bluetooth.defaultAdapter ?? (Bluetooth.adapters?.values?.[0] ?? null)
    readonly property bool btPowered: btAdapter?.enabled ?? false
    readonly property int btConnectedCount: (btAdapter?.devices?.values ?? []).filter(d => d.connected).length
    readonly property color bluetoothColor: !btPowered ? Theme.on_surface_variant : (btConnectedCount > 0 ? Theme.primary : Theme.on_surface)

    function bluetoothIcon() {
        if (!btPowered) return "bluetooth_disabled";
        return btConnectedCount > 0 ? "bluetooth_connected" : "bluetooth";
    }

    // --- Volume ---
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

    // --- Battery ---
    readonly property var battery: UPower.displayDevice
    readonly property bool batteryPresent: battery?.isLaptopBattery ?? false
    readonly property real batteryPct: (battery?.percentage ?? 0) * 100
    readonly property bool batteryCharging: battery?.state === UPowerDeviceState.Charging || battery?.state === UPowerDeviceState.PendingCharge

    readonly property color batteryColor: (batteryPct < 20 && !batteryCharging) ? Theme.critical : Theme.on_surface


    Rectangle {
        id: visualPill
        anchors.centerIn: parent

        implicitWidth: iconsRow.implicitWidth + 32
        implicitHeight: iconsRow.implicitHeight + 16
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
            spacing: 14

            Text {
                text: root.networkIcon()
                color: root.networkColor
                anchors.verticalCenter: parent.verticalCenter
                font { family: "Material Symbols Rounded"; pixelSize: 20 }
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

            // Custom Android/OneUI Style Battery Pill
            Row {
                visible: root.batteryPresent
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter

                // The Main Battery Pill
                Item {
                    width: 34
                    height: 18
                    anchors.verticalCenter: parent.verticalCenter

                    // The background track
                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: root.batteryColor
                        opacity: 0.25
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    // The active charge fill (caps out at 98%)
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom

                        // Maps 0-98% to the full width of the main pill
                        width: Math.max(height, parent.width * Math.min(1.0, root.batteryPct / 98))
                        radius: height / 2
                        color: root.batteryColor

                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    // The Charging Bolt & Percentage Text
                    Row {
                        anchors.centerIn: parent
                        spacing: 0

                        IconImage {
                            visible: root.batteryCharging
                            source: "file://" + Quickshell.shellPath("assets/bolt.svg")
                            color: root.batteryPct > 65 ? Theme.surface_container : root.batteryColor
                            width: 14
                            height: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            visible: !(root.batteryCharging && root.batteryPct === 100)
                            text: Math.round(root.batteryPct)
                            color: root.batteryPct > (root.batteryCharging ? 75 : 55) ? Theme.surface_container : root.batteryColor
                            font {
                                family: "Google Sans"
                                pixelSize: 12
                                weight: Font.Bold
                            }
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // The battery terminal "nub" (Fills from 98% to 100%)
                Item {
                    width: 3
                    height: 10
                    anchors.verticalCenter: parent.verticalCenter

                    // Nub background track
                    Rectangle {
                        anchors.fill: parent
                        radius: 1.5
                        color: root.batteryColor
                        opacity: 0.25
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    // Nub active fill
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom

                        // Starts filling at 98%, reaches 50% at 99%, fully solid at 100%
                        width: parent.width * Math.max(0, Math.min(1.0, (root.batteryPct - 98) / 2))
                        radius: 1.5
                        color: root.batteryColor

                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }
        }
    }
}
