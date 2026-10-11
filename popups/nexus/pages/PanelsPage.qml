import QtQuick
import qs.theme
import qs.popups.settings
import qs.popups.nexus
import qs.popups.nexus.common

PageBase {
    id: root

    title: "Panels"
    description: "Bars, tray and status items"

    SettingsGroup {
        title: "Top bar"
        description: "Always spans the full width of each monitor."

        InfoRow {
            label: "Height"
            value: Math.round(Layout.topBarHeight) + " px"
        }
        InfoRow {
            label: "Hidden on fullscreen"
            value: "yes"
        }
    }

    SettingsGroup {
        title: "Status"

        InfoRow {
            label: "Workspace slots"
            value: "1 - 10"
        }
        InfoRow {
            label: "Clock"
            value: "centre"
        }
        InfoRow {
            label: "Tray and status"
            value: "right"
        }
    }

    SectionHeader {
        text: "Not yet configurable"
        description: "Panel layout is currently fixed in bar/TopBar.qml. Making the entries reorderable means describing them in data and instantiating from that, the way Caelestia's Bar.qml does with Config.bar.entries."
    }
}
