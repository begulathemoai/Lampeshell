import QtQuick
import QtQuick.Controls
import Quickshell.Hyprland
import qs.theme
import qs.services
import qs.popups.settings
import qs.popups.nexus
import qs.popups.nexus.common

PageBase {
    id: root

    title: "Display"
    description: "Brightness per output"

    SettingsGroup {
        title: "Brightness"

        SliderRow {
            icon: "brightness_6"
            label: "Brightness"
            value: root.nState.quickSettingsBackend.brightnessLevel * 100
            from: 0
            to: 100
            onMoved: function(v) {
                root.nState.quickSettingsBackend.setBrightness(v / 100);
            }
        }
    }
}
