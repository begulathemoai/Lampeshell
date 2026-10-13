pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Night light: the blue-light filter, driven from the settings app instead
// of from an unconditional line in the Hyprland config.
//
// It used to be started by `sleep 1 && gammastep` in hyprland/execs.lua,
// which meant it was on from login to logout with no way to change it and no
// way to turn it off. Hyprland's autostart for it is removed; this applies
// the stored state once the shell is up, so the setting survives a session
// restart and still wins over whatever the compositor might have set.
//
// gammastep's own flags (gammastep -h):
//   -O TEMP  one-shot manual temperature
//   -P       reset the gamma correction before applying a new effect
//   -x       reset, i.e. turn the adjustment off
// Neutral is 6500 K; its own night default is 4500 K.
Singleton {
    id: root

    // Off by default. It used to be unconditionally on.
    property bool enabled: SettingsStore.get("nightLightEnabled") === true
    property real temperature: {
        const v = Number(SettingsStore.get("nightLightTemperature"));
        return isNaN(v) || v <= 0 ? 4500 : v;
    }

    // Whether the binary is actually there, so the settings row can say so
    // instead of appearing to work and doing nothing.
    property bool available: false
    property string unavailableReason: ""
    // Whatever gammastep last said, for the settings row to show if useful.
    property string lastMessage: ""
    // gammastep reports when the display cannot take a gamma adjustment at
    // all ("Zero outputs support gamma adjustment"). On such a display the
    // toggle is honest but inert, and the row has to say so rather than
    // pretending it is filtering.
    property bool supported: true

    // Range: below 1000 K gammastep produces nonsense, above 6500 K it is
    // not a night light any more - that is neutral, and higher is daylight
    // blue, which is the opposite of what this row is for.
    readonly property real minTemperature: 1000
    readonly property real maxTemperature: 6500

    function setEnabled(on) {
        if (enabled === on)
            return;
        enabled = on;
        SettingsStore.set("nightLightEnabled", on);
        apply();
    }

    function setTemperature(kelvin) {
        const clamped = Math.max(minTemperature, Math.min(maxTemperature, kelvin));
        const rounded = Math.round(clamped / 50) * 50;
        if (temperature === rounded)
            return;
        temperature = rounded;
        SettingsStore.set("nightLightTemperature", rounded);
        apply();
    }

    function apply() {
        if (!available) {
            if (enabled)
                unavailableReason = "gammastep was not found on PATH";
            return;
        }
        unavailableReason = "";
        if (enabled) {
            // Any gammastep already running was started by something else -
            // Hyprland's autostart, most likely - and bare `gammastep` means
            // the automatic day/night schedule, which re-applies its own
            // temperature and quietly overrides whatever we ask for. Stop it
            // first so the only thing adjusting the screen is us.
            stopResident.running = false;
            stopResident.running = true;
            setProc.command = ["gammastep", "-P", "-O", String(Math.round(temperature))];
            setProc.running = false;
            setProc.running = true;
        } else {
            stopResident.running = false;
            stopResident.running = true;
            resetProc.running = false;
            resetProc.running = true;
        }
    }

    Process {
        id: stopResident
        command: ["pkill", "-x", "gammastep"]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    Process {
        id: setProc
        stdout: StdioCollector {}
        stderr: StdioCollector {
            // Only used for reporting. gammastep writes to stderr on
            // success too (it narrates the gamma method it picked), so this
            // must not be read as "not installed" - that used to make the
            // toggle report itself missing the moment it was used.
            onStreamFinished: {
                const t = this.text.trim();
                if (t.length > 0 && root.available) {
                    root.lastMessage = t.split("\n")[0];
                    root.supported = !/support(s)? gamma adjustment|do not support/i.test(t);
                }
            }
        }
    }

    Process {
        id: resetProc
        command: ["gammastep", "-x"]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    Process {
        id: probe
        command: ["sh", "-c", "command -v gammastep || exit 1"]
        stdout: StdioCollector {}
        onExited: exitCode => {
            root.available = exitCode === 0;
            if (!root.available)
                root.unavailableReason = "gammastep was not found on PATH";
            else
                root.apply();
        }
    }

    Component.onCompleted: probe.running = true

    IpcHandler {
        target: "nightLight"

        function setEnabled(on: bool): void {
            root.setEnabled(on);
        }

        function setTemperature(kelvin: real): void {
            root.setTemperature(kelvin);
        }

        function state(): string {
            return JSON.stringify({
                available: root.available,
                supported: root.supported,
                enabled: root.enabled,
                temperature: root.temperature,
                reason: root.unavailableReason,
                message: root.lastMessage
            });
        }
    }
}