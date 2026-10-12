import QtQuick
import qs.theme
import qs.services
import qs.popups.settings
import qs.popups.nexus
import qs.popups.nexus.common

PageBase {
    id: root

    title: "Notifications"
    description: "Do-not-disturb and timeout behaviour"

    SettingsGroup {
        title: "Do not disturb"
        description: "When enabled, new notifications are recorded in history but no popups are shown."

        ToggleRow {
            label: "Enable DND"
            checked: Notifs.dnd
            onToggled: Notifs.toggleDnd()
        }
    }

    SettingsGroup {
        title: "Status"
        description: "Read from the running notification server."

        InfoRow {
            label: "Current history"
            value: Notifs.notClosed.length + " notification" + (Notifs.notClosed.length === 1 ? "" : "s")
        }
        InfoRow {
            label: "Default timeout"
            value: Math.round(Notifs.defaultExpireTimeout / 1000) + "s"
        }
        InfoRow {
            label: "Fullscreen timeout"
            value: Math.round(Notifs.fullscreenExpireTimeout / 1000) + "s"
        }
        InfoRow {
            label: "Last error"
            value: Notifs.lastError.length > 0 ? Notifs.lastError : "none"
        }
    }

    SectionHeader {
        text: "About"
        description: "Notifications are persisted to ~/.local/state/lampshell/notifs.json and survive shell reloads. The DND toggle survives across all restarts. Use the IPC target 'notifs' (clear, isDndEnabled, toggleDnd, enableDnd, disableDnd) to control this from scripts."
    }
}
