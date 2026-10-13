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
    description: "Brightness and colour temperature"

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

    SettingsGroup {
        title: "Night light"
        description: "Blue light filter. Applied live, and reapplied on login."

        ToggleRow {
            icon: "light_mode"
            label: "Enabled"
            checked: NightLight.enabled
            enabled: NightLight.available
            onToggled: function(checked) {
                NightLight.setEnabled(checked);
            }
        }

        SliderRow {
            icon: "thermostat"
            label: "Temperature"
            suffix: " K"
            from: NightLight.minTemperature
            to: NightLight.maxTemperature
            value: NightLight.temperature
            enabled: NightLight.available && NightLight.enabled
            onMoved: function(v) {
                NightLight.setTemperature(v);
            }
        }

        InfoRow {
            label: "Status"
            value: !NightLight.available
                ? "gammastep not installed"
                : (!NightLight.supported
                    ? "display cannot adjust gamma"
                    : (NightLight.enabled
                        ? "on at " + Math.round(NightLight.temperature) + " K"
                        : "off"))
        }
    }
}
