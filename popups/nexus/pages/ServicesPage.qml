import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import qs.theme
import qs.services
import qs.popups.settings
import qs.popups.nexus
import qs.popups.nexus.common

PageBase {
    id: root

    readonly property var backend: root.nState.quickSettingsBackend

    title: "Services"
    description: "Notifications and shell integrations"

    SettingsGroup {
        title: "Status"
        description: "Services the shell talks to."

        InfoRow {
            label: "Compositor"
            value: Hyprland.usingLua ? "Hyprland (Lua dispatch)" : "Hyprland (legacy dispatch)"
        }
        InfoRow {
            label: "Networking"
            value: Networking.devices?.values?.length > 0
                ? Networking.devices.values.length + " interface(s)"
                : "none"
        }
        InfoRow {
            label: "Bluetooth"
            value: root.backend.btAdapter
                ? (root.backend.btPowered ? "adapter on" : "adapter off")
                : "no adapter"
        }
        InfoRow {
            label: "Tray"
            value: SystemTray.items?.values?.length > 0
                ? SystemTray.items.values.length + " item(s)"
                : "empty"
        }
    }

    SettingsGroup {
        title: "Bluetooth"
        description: "Adapter radio, separate from the Bluetooth page's device list."

        ToggleRow {
            icon: "power_settings_new"
            label: "Adapter powered"
            checked: root.backend.btPowered
            enabled: root.backend.btAdapter !== null
            onToggled: checked => root.backend.setBluetooth(checked)
        }
    }

    SectionHeader {
        text: "Fullscreen detection"
        description: "The bar reads fullscreen state from a 120 ms poll. HyprlandWorkspace.hasFullscreen does not emit a notify signal in quickshell 0.3.1, so a plain binding silently freezes at its first value."
    }
}
