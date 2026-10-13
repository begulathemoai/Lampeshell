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

        SelectRow {
            label: "Method"
            model: [
                { label: "Auto", value: "auto" },
                { label: "Display", value: "ddc" },
                { label: "Gamma", value: "gamma" },
                { label: "Filter", value: "overlay" }
            ]
            value: NightLight.backend
            onSelected: function(v) {
                NightLight.setBackend(v);
            }
        }

        InfoRow {
            label: "Status"
            value: {
                if (!NightLight.available) {
                    if (!NightLight.ddcPresent && !NightLight.gammaPresent)
                        return "install ddcutil or gammastep";
                    if (NightLight.ddcDisplays > 0)
                        return "this display accepts no colour setting";
                    return "no gamma-capable output";
                }
                if (NightLight.scanningPresets)
                    return "learning display presets…";
                if (!NightLight.enabled)
                    return "off";
                // A screen filter is not a colour temperature, and quoting a
                // Kelvin value for it would be the same lie as before.
                if (NightLight.resolvedBackend === "overlay")
                    return "screen filter toward "
                        + Math.round(NightLight.temperature) + " K";
                if (NightLight.resolvedBackend === "gamma" && !NightLight.gammaSupported)
                    return "screen gamma unavailable";
                if (NightLight.ddcControl === "0x14" && !NightLight.presetsUsable)
                    return "no warmer preset on this display";
                if (NightLight.writePending)
                    return "applying…";
                if (!NightLight.writeVerified)
                    return "display refused the change";
                if (NightLight.achievedKelvin > 0
                    && Math.abs(NightLight.achievedKelvin - NightLight.temperature) > 100)
                    return "closest the display offers: " + NightLight.achievedKelvin + " K";
                return "on at " + Math.round(NightLight.temperature) + " K";
            }
        }
    }
}
