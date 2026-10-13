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
            label: "Method"
            value: NightLight.ddcDisplays > 0
                ? "Display (DDC), " + NightLight.ddcDisplays + " display(s)"
                : (NightLight.gammaPresent
                    ? (NightLight.gammaSupported ? "Screen gamma" : "Screen gamma unavailable")
                    : "no method available")
        }

        InfoRow {
            label: "Status"
            value: !NightLight.available
                ? "install ddcutil or gammastep"
                : (NightLight.scanningPresets
                    ? "learning display presets…"
                    : (!NightLight.enabled
                        ? "off"
                        : (NightLight.resolvedBackend === "gamma" && !NightLight.gammaSupported
                            ? "screen gamma unavailable"
                            : (NightLight.ddcControl === "0x14"
                                && Object.keys(NightLight.presetTable ?? {}).length === 0
                                ? "display offers no usable temperature preset"
                                : (NightLight.writePending
                                    ? "applying…"
                                    : (NightLight.writeVerified
                                        ? "on at " + Math.round(NightLight.temperature) + " K"
                                        : "display refused the change"))))))
        }
    }
}
