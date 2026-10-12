import QtQuick
import qs.theme
import qs.services
import qs.popups.settings
import qs.popups.nexus
import qs.popups.nexus.common

PageBase {
    id: root

    readonly property var backend: root.nState.quickSettingsBackend

    title: "Network"
    description: "Wi-Fi and saved networks"

    SettingsGroup {
        title: "Wi-Fi"
        description: backend.wifiDevice
            ? (backend.wifiEnabled ? "On" : "Off")
            : "No wireless device"

        ToggleRow {
            icon: "wifi"
            label: "Wi-Fi"

            checked: backend.wifiEnabled
            enabled: backend.wifiDevice !== null
            onToggled: checked => backend.setWifi(checked)
        }
    }

    SettingsGroup {
        title: "Wired"

        Repeater {
            model: backend.networkDevices

            delegate: InfoRow {
                required property var modelData
                label: modelData.name ?? modelData.identifier ?? "interface"
                value: modelData.connected ? "up" : "down"
            }
        }

        InfoRow {
            visible: backend.networkDevices.length === 0
            label: "No wired interfaces"
            value: ""
        }
    }

    SettingsGroup {
        title: "Saved networks"
        description: backend.visibleNetworks.length === 0
            ? "Nothing saved on this device."
            : backend.visibleNetworks.length + " network(s)."

        Repeater {
            model: backend.visibleNetworks

            delegate: SettingsRow {
                required property var modelData
                required property int index

                icon: modelData.connected === true ? "wifi" : "wifi_off"
                label: modelData.name ?? modelData.ssid ?? "Unknown"
                description: modelData.connected === true ? "Connected" : "Tap to connect"
                onClicked: backend.toggleNetwork(modelData)
            }
        }

        InfoRow {
            visible: backend.visibleNetworks.length === 0
            label: "No saved networks"
            value: ""
        }
    }
}
