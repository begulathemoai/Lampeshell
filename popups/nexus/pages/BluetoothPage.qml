import QtQuick
import Quickshell
import qs.theme
import qs.services
import qs.popups.settings
import qs.popups.nexus
import qs.popups.nexus.common

PageBase {
    id: root

    readonly property var backend: root.nState.quickSettingsBackend

    title: "Bluetooth"
    description: "Adapter and paired devices"

    SettingsGroup {
        title: "Adapter"
        description: backend.btAdapter
            ? (backend.btPowered
                ? "On · " + (backend.btAdapter.name || "adapter")
                : "Off")
            : "No adapter found"

        ToggleRow {
            icon: "bluetooth"
            label: "Bluetooth"
            checked: backend.btPowered
            enabled: backend.btAdapter !== null
            onToggled: checked => backend.setBluetooth(checked)
        }

        ToggleRow {
            icon: "radar"
            label: "Discoverable"
            checked: backend.btAdapter?.discovering ?? false
            enabled: backend.btAdapter !== null
            onToggled: checked => backend.setDiscovering(checked)
        }
    }

    SettingsGroup {
        title: "Paired devices"
        description: backend.btKnownDevices.length === 0
            ? "Nothing paired yet."
            : backend.btKnownDevices.length + " device(s)."

        Repeater {
            model: backend.btKnownDevices

            delegate: DeviceRow {
                required property var modelData
                device: modelData
                busy: backend.btBusyAddress === (modelData.address ?? "")
                onAction: backend.toggleDevice(modelData)
                onForgotten: backend.forgetDevice(modelData)
            }
        }

        InfoRow {
            visible: backend.btKnownDevices.length === 0
            label: "No paired devices"
            value: "Pair one below"
        }
    }

    SettingsGroup {
        title: "Available devices"
        description: backend.btAdapter?.discovering
            ? "Scanning · tap a device to pair."
            : "Turn on Discoverable to scan for nearby devices."

        Repeater {
            model: backend.btAvailableDevices

            delegate: DeviceRow {
                required property var modelData
                device: modelData
                busy: backend.btBusyAddress === (modelData.address ?? "")
                onAction: backend.pairDevice(modelData)
            }
        }

        InfoRow {
            visible: backend.btAvailableDevices.length === 0
            label: backend.btAdapter?.discovering ? "Scanning" : "Not scanning"
            value: backend.btAvailableDevices.length === 0 ? "no results" : ""
        }
    }

    SettingsGroup {
        title: "Advanced"
        description: "Pairing is handled in-shell; blueman-manager is only for troubleshooting."

        ActionButton {
            text: "Open blueman-manager"
            icon: "bluetooth_audio"
            onTriggered: Quickshell.execDetached({ command: ["blueman-manager"] })
        }
    }
}
