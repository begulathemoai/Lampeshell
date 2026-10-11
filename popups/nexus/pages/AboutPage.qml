import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.theme
import qs.services
import qs.popups.settings
import qs.popups.nexus
import qs.popups.nexus.common

PageBase {
    id: root

    readonly property var screen: root.nState.targetScreen

    title: "About"
    description: "System information and credits"

    SettingsGroup {
        title: "System"
        description: "Session and display information."

        InfoRow {
            label: "Compositor"
            value: "Hyprland " + (Hyprland.version || "")
        }
        InfoRow {
            label: "Shell"
            value: "octashell on quickshell " + (Quickshell.version || "")
        }
        InfoRow {
            label: "Session"
            value: root.screen
                ? root.screen.name + " @ " + (root.screen.width * root.screen.scale) + "x" + (root.screen.height * root.screen.scale)
                : "unknown"
        }
    }

    SettingsGroup {
        title: "Outputs"
        description: "Connected displays."

        Repeater {
            model: Quickshell.screens

            delegate: InfoRow {
                required property var modelData
                label: modelData.name
                value: (modelData.width * modelData.scale) + "x" + (modelData.height * modelData.scale)
            }
        }
    }
}
