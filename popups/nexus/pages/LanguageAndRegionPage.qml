import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme
import qs.services
import qs.popups.settings
import qs.popups.nexus
import qs.popups.nexus.common

PageBase {
    id: root

    title: "Language & region"
    description: "Locale, formats and timezone"

    readonly property string locale: Qt.locale().name
    readonly property string timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone ?? ""

    SettingsGroup {
        title: "Current"
        description: "Read from the running environment."

        InfoRow {
            label: "Locale"
            value: root.locale.length > 0 ? root.locale : "not set"
        }
        InfoRow {
            label: "Timezone"
            value: root.timeZone.length > 0 ? root.timeZone : "not set"
        }
        InfoRow {
            label: "24-hour clock"
            value: root.locale.indexOf("en_GB") === 0 || root.locale.indexOf("de") === 0 ? "yes" : "no"
        }
    }

    SettingsGroup {
        title: "Keyboard"
        description: "Layouts are configured in hyprland/keybinds.lua and hyprland/misc.lua; the shell reads them rather than owning them."
    }
}
