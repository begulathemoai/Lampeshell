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

    Column {
        width: parent.width
        spacing: 0

        Repeater {
            model: Audio.sinks

            delegate: AudioDeviceRow {
                required property var modelData
                required property int index

                node: modelData
                isActive: modelData === Audio.activeSink
                height: Layout.s(52)
                width: parent.width
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

    Column {
        width: parent.width
        spacing: 0
        visible: Audio.sources.length > 1

        Repeater {
            model: Audio.sources

            delegate: AudioDeviceRow {
                required property var modelData
                required property int index

                node: modelData
                isInput: true
                isActive: modelData === Audio.activeSource
                height: Layout.s(52)
                width: parent.width
                onActivated: Audio.setSource(modelData)
            }
        }
    }

    Column {
        width: parent.width
        spacing: 0
        visible: Audio.audibleStreams.length > 0

        SectionHeader {
            width: parent.width
            text: "Applications"
        }

        Repeater {
            model: Audio.audibleStreams

            delegate: Column {
                required property var modelData
                width: parent.width

                SliderRow {
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
}