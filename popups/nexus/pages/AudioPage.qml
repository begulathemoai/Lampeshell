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

    readonly property var backend: root.nState.quickSettingsBackend

    title: "Audio"
    description: "Output, input and per-app volumes"

    SettingsGroup {
        title: "Output"
        description: Audio.activeSink ? Audio.displayName(Audio.activeSink) : "No output device"

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
        title: "Output devices"

        Repeater {
            model: Audio.sinks

            delegate: AudioDeviceRow {
                required property var modelData

                node: modelData
                isActive: modelData === Audio.activeSink
                onActivated: Audio.setSink(modelData)
            }
        }
    }

    SettingsGroup {
        title: "Input"
        description: Audio.activeSource ? Audio.displayName(Audio.activeSource) : "No input device"

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

    SettingsGroup {
        title: "Input devices"
        visible: Audio.sources.length > 0

        Repeater {
            model: Audio.sources

            delegate: AudioDeviceRow {
                required property var modelData

                node: modelData
                isInput: true
                isActive: modelData === Audio.activeSource
                onActivated: Audio.setSource(modelData)
            }
        }
    }

    SettingsGroup {
        title: "Applications"
        visible: Audio.audibleStreams.length > 0

        Repeater {
            model: Audio.audibleStreams

            delegate: SliderRow {
                required property var modelData

                icon: Audio.iconForStream(modelData)
                label: Audio.displayName(modelData)
                value: Math.round((modelData.audio?.volume ?? 0) * 100)
                from: 0
                to: 100
                onMoved: function(v) {
                    Audio.setStreamVolume(modelData, v / 100);
                }
            }
        }
    }
}
