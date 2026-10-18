import QtQuick
import qs.theme
import qs.services
import qs.popups.settings
import qs.popups.nexus
import qs.popups.nexus.common

PageBase {
    id: root

    title: "Panels"
    description: "Bars, tray and status items"

    readonly property string position: Layout.barPosition

    function positions() {
        return [
            { key: "top", label: "Top", icon: "vertical_align_top" },
            { key: "bottom", label: "Bottom", icon: "vertical_align_bottom" },
            { key: "left", label: "Left", icon: "align_horizontal_left" },
            { key: "right", label: "Right", icon: "align_horizontal_right" }
        ];
    }

    SettingsGroup {
        title: "Bar position"
        description: "Move the bar to any edge. Panels follow the bar."

        Row {
            width: parent.width
            spacing: 8

            Repeater {
                model: root.positions()

                SegmentedChoice {
                    required property var modelData

                    width: (parent.width - 24) / 4
                    label: modelData.label
                    icon: modelData.icon
                    active: root.position === modelData.key
                    onPicked: SettingsStore.set("barPosition", modelData.key)
                }
            }
        }
    }

    SettingsGroup {
        title: "Bar"
        description: "Always spans the full edge of each monitor."

        InfoRow {
            label: "Thickness"
            value: Math.round(Layout.barThickness) + " px"
        }
        InfoRow {
            label: "Hidden on fullscreen"
            value: "yes"
        }
        ToggleRow {
            icon: "music_note"
            label: "Show Now Playing widget"
            description: "Shows the Now Playing status and allows to control playback directly from your bar."

            checked: SettingsStore.values.musicPlayerWidgetEnabled
            onToggled: checked => SettingsStore.set("musicPlayerWidgetEnabled", checked)
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
            value: "end"
        }
    }
}
