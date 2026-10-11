import QtQuick
import Quickshell.Hyprland
import qs.theme
import qs.services
import qs.popups.settings
import qs.popups.nexus
import qs.popups.nexus.common

PageBase {
    id: root

    readonly property var backend: root.nState.quickSettingsBackend

    title: "Audio"
    description: "Output, input and app volumes"

    SettingsGroup {
        title: "Output"
        description: backend.activeSink?.name || "Default output"

        SliderRow {
            icon: backend.isMuted ? "volume_off" : "volume_up"
            label: "Volume"
            value: backend.volumePercent
            from: 0
            to: 100
            onMoved: function(v) {
                backend.setVolume(v / 100);
            }
        }
    }

    SettingsGroup {
        title: "Input"
        description: backend.activeSource?.name || "Default input"

        SliderRow {
            icon: backend.isMutedSource ? "mic_off" : "mic"
            label: "Input volume"
            value: backend.microphonePercent
            from: 0
            to: 100
            onMoved: function(v) {
                backend.setMicrophone(v / 100);
            }
        }
    }
}
