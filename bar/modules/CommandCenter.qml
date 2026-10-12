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

    signal clicked

    implicitWidth: visualPill.implicitWidth
    implicitHeight: visualPill.implicitHeight

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

            Row {
                visible: root.batteryPresent
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter

                Item {
                    width: 34
                    height: 18
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: root.batteryColor
                        opacity: 0.25
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom

                        width: Math.max(height, parent.width * Math.min(1.0, root.batteryPct / 98))
                        radius: height / 2
                        color: root.batteryColor

                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

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

                Item {
                    width: 3
                    height: 10
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: 1.5
                        color: root.batteryColor
                        opacity: 0.25
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom

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
