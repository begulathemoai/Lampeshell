pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Night light: the blue light filter, driven from the settings app instead
// of from an unconditional line in the Hyprland config.
//
// It used to be started by `sleep 1 && gammastep` in hyprland/execs.lua,
// which meant it was on from login to logout with no way to change it and no
// way to turn it off. Hyprland's autostart for it is removed; this applies
// the stored state once the shell is up, so the setting survives a session
// restart.
//
// Portability, because this is a shared shell and hardware differs:
// nothing here names a gamma method or a DRM card. gammastep picks its own
// default, and a user whose display needs something else sets `method` in
// the store (`lampshell ipc nightLight setMethod "drm:card=1"`) rather than
// anyone editing this file for their box.
//
// gammastep flags, from `gammastep -h`:
//   -O TEMP   one-shot manual temperature
//   -P        reset the gamma correction before applying a new effect
//   -x        reset, i.e. turn the adjustment off
//   -m METHOD[:OPTIONS]  which adjustment backend to use
// Neutral is 6500 K; gammastep's own night default is 4500 K.
//
// Whether a display can take a gamma adjustment at all is a property of the
// machine, not of this shell: gammastep reports "Zero outputs support gamma
// adjustment" and exits successfully on displays that cannot. When that
// happens the setting says so and stops pretending to be filtering, rather
// than toggling a flag that does nothing.
Singleton {
    id: root

    property bool enabled: SettingsStore.get("nightLightEnabled") === true

    property real temperature: {
        const v = Number(SettingsStore.get("nightLightTemperature"));
        return isNaN(v) || v <= 0 ? 4500 : v;
    }

    // Empty means "let gammastep decide". Only set this if your display needs
    // it - see gammastep -m list and gammastep -m METHOD:help.
    property string method: String(SettingsStore.get("nightLightMethod") ?? "")

    property bool available: false
    property string unavailableReason: ""
    property string lastMessage: ""
    // gammastep reports when the display cannot take a gamma adjustment at
    // all. On such a display the toggle is honest but inert, and the row has
    // to say so instead of claiming to be filtering.
    property bool supported: true

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

    function setMethod(value) {
        const m = String(value ?? "").trim();
        if (method === m)
            return;
        method = m;
        SettingsStore.set("nightLightMethod", m);
        supported = true;
        apply();
    }

    function command(extra) {
        const base = ["gammastep"];
        if (method.length > 0)
            base.push("-m", method);
        return base.concat(extra);
    }

    function apply() {
        if (!available) {
            if (enabled)
                unavailableReason = "gammastep was not found on PATH";
            return;
        }
        unavailableReason = "";
        // A gammastep left over from Hyprland's old autostart runs bare,
        // meaning the automatic day/night schedule, which re-applies its own
        // temperature and overrides everything asked for here.
        //
        // It has to be gone before a replacement starts: wlr-gamma-control
        // belongs to one client at a time, so a replacement launched in the
        // same tick asks for a control the compositor has not released yet
        // and comes back "Zero outputs support gamma adjustment", which reads
        // exactly like the feature being broken.
        stopResident.running = false;
        stopResident.running = true;
        settle.restart();
    }

    function startApply() {
        if (enabled) {
            // -P first so a second change does not stack on the first.
            setProc.command = command(["-P", "-O", String(Math.round(temperature))]);
            setProc.running = false;
            setProc.running = true;
        } else {
            // The reset must use the same backend as the apply, or it resets
            // something that was never set: gammastep -x with the default
            // method on a machine using another one reports zero adjustable
            // outputs and leaves the filter in place.
            resetProc.command = command(["-x"]);
            resetProc.running = false;
            resetProc.running = true;
        }
    }

    Timer {
        id: settle
        interval: 350
        onTriggered: root.startApply()
    }

    function noteOutput(text) {
        const t = String(text ?? "").trim();
        if (t.length === 0 || !available)
            return;
        root.lastMessage = t.split("\n")[0];
        root.supported = !/zero outputs support gamma|do not support gamma/i.test(t);
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
            // gammastep narrates on stderr even when nothing is wrong (it
            // names the adjustment method it picked), so this must never be
            // read as "not installed". An earlier version did, and the toggle
            // reported itself missing the moment it was used.
            onStreamFinished: root.noteOutput(this.text)
        }
    }

    Process {
        id: resetProc
        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: root.noteOutput(this.text)
        }
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

        function setMethod(value: string): void {
            root.setMethod(value);
        }

        function state(): string {
            return JSON.stringify({
                available: root.available,
                supported: root.supported,
                enabled: root.enabled,
                temperature: root.temperature,
                method: root.method,
                reason: root.unavailableReason,
                message: root.lastMessage
            });
        }
    }
}