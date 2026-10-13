pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Night light: lowers the display's colour temperature in the evening.
//
// It used to be started unconditionally from hyprland/execs.lua as a bare
// `gammastep`, which means "pick the temperature yourself from the clock and
// a geoclue location" - on at login with no way to change or disable it. That
// autostart is gone; this applies the stored state at shell startup and
// whenever the setting changes.
//
// Two backends, because neither works everywhere:
//
//   ddc    - ddcutil writing VCP 0x0b on the monitor itself. Works on
//            external displays regardless of graphics driver, including
//            NVIDIA, where gamma cannot work at all. Preferred.
//   gamma  - gammastep via the compositor's gamma-control protocol. Works on
//            integrated/Intel/AMD displays; reports zero adjustable outputs
//            on the NVIDIA proprietary driver, which does not expose CRTC
//            gamma ramps to wlroots.
//
// "auto" prefers ddc and falls back to gamma. The choice can be pinned per
// user, because which of the two actually works is a property of the
// hardware, not of this shell.
//
// Nothing here names a monitor, a bus or a graphics card.
//
// ddcutil notes for this path, from `ddcutil getvcp 0c` on a display that
// supports it: the monitor's colour temperature is
//     3000 + 35 * (VCP 0x0b value)
// so 0x0b is a step count, and it is the nicest control when a display
// lets you write it - continuous, 3000 K..6500 K.
//
// Plenty of displays do not. A BenQ/Eizo EW3270U reports 0x0b as read-only
// ("Feature 0x0b (Color temperature increment) is not writable") and
// exposes 0x14 "Select color preset" instead, which reads back in Kelvin -
// on that one 0x04 is 5000 K and 0x05 is 6500 K. The preset index to Kelvin
// mapping is per-model, so it is discovered by walking the preset values and
// reading each one back, then cached. That walk flickers the screen once,
// on first use, and only for displays that need it.
//
// 0x1a "Video gain: Blue" is the last resort: almost universally writable,
// continuous, but crude - it shifts the blue channel rather than setting a
// temperature, so the slider's Kelvin number is a rough label on it.
//
// Whichever control is used, "off" means the neutral end of that control,
// not "leave it where it was".
//
// Values are deliberately not saved into the monitor's non-volatile memory
// (ddcutil savevcp): the filter should not outlive the session, and a
// monitor left warm after a crash is a bad surprise to come back to.
Singleton {
    id: root

    property bool enabled: SettingsStore.get("nightLightEnabled") === true

    property real temperature: {
        const v = Number(SettingsStore.get("nightLightTemperature"));
        return isNaN(v) || v <= 0 ? 4500 : v;
    }

    // "auto" | "ddc" | "gamma"
    property string backend: String(SettingsStore.get("nightLightBackend") ?? "auto")

    property string resolvedBackend: ""

    property bool ddcPresent: false
    property int ddcDisplays: 0
    // Which VCP this display actually accepts for colour temperature:
    // "0x0b" (continuous steps), "0x14" (presets) or "0x1a" (blue gain).
    // Empty until probed, or when none of them is writable.
    property string ddcControl: ""
    // kelvin -> preset index, learned by walking the presets once and kept
    // in the store so it costs one flicker per machine, not per session.
    property var presetTable: JSON.parse(String(SettingsStore.get("nightLightPresets") ?? "{}"))
    property bool scanningPresets: false

    property bool gammaPresent: false
    property bool gammaSupported: false

    // Learned from the display itself rather than assumed, because these
// differ between monitor models:
//   tempBase/tempStep  - 0x0b's units. A BenQ/Eizo EW3270U describes 0x0c as
//                        "3000 + 35 * (feature 0B color temp increment)", so
//                        0x0b is a step count from 3000 K in 35 K steps.
//                        Other displays describe their own base and step;
//                        if 0x0c says nothing parseable, these stay at that
//                        same widely-used default.
//   blueMax           - 0x1a's full-scale value, read from the display.
property real tempBase: 3000
property real tempStep: 35
property int blueMax: 65535

// Which display the writability probe found a usable control on. Writes go
// to every display that reported the feature, but the probe has to happen on
// one of them, and the first one is not guaranteed to be the one with colour
// control.
property int probeDisplay: 1

property string lastMessage: ""

    // Whether the last write actually took, checked by reading the control
    // back. A display can advertise a colour feature and still refuse the
    // write - the BenQ/Eizo EW3270U answers DDCRC_VERIFY for presets it does
    // not recognise, and started refusing ones it had accepted minutes
    // earlier - so "we sent it" is not "it happened". The status row reports
    // this instead of claiming to be filtering.
    property bool writeVerified: false
    property bool writePending: false
    property int expectedValue: 0

    // DDC can only reach the monitor's own range. Gamma can go much warmer
    // than any monitor offers, which is why the slider bounds follow the
    // backend in use.
    readonly property real ddcMin: 3000
    readonly property real ddcMax: 6500
    readonly property real gammaMin: 1000
    readonly property real gammaMax: 6500

    readonly property real minTemperature: resolvedBackend === "ddc" ? ddcMin : gammaMin
    readonly property real maxTemperature: 6500

    readonly property bool available: resolvedBackend.length > 0

    function setEnabled(on) {
        if (enabled === on)
            return;
        enabled = on;
        SettingsStore.set("nightLightEnabled", on);
        recheck();
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

    function setBackend(value) {
        const b = String(value ?? "auto").trim() || "auto";
        if (backend === b)
            return;
        // Leaving a backend warm behind would tint the screen with nothing
        // able to turn it back off.
        restore();
        backend = b;
        SettingsStore.set("nightLightBackend", b);
        recheck();
    }

    // Re-probing rather than caching matters: which backend works can change
    // under a running session (a monitor plugged in, Hyprland restarted, a
    // different cable), and a stale answer leaves the toggle inert.
    function recheck() {
        lastMessage = "";
        probeDdc.running = false;
        probeDdc.running = true;
        probeGamma.running = false;
        probeGamma.running = true;
    }

    function resolve() {
        if (backend === "ddc" && ddcDisplays > 0) {
            resolvedBackend = "ddc";
        } else if (backend === "gamma" && gammaPresent) {
            resolvedBackend = "gamma";
        } else if (ddcDisplays > 0) {
            resolvedBackend = "ddc";
        } else if (gammaPresent) {
            resolvedBackend = "gamma";
        } else {
            resolvedBackend = "";
        }
        if (resolvedBackend.length > 0)
            apply();
    }

    // step = (kelvin - base) / step, in this display's own units
    function stepFor(kelvin) {
        const clamped = Math.max(tempBase, Math.min(ddcMax, kelvin));
        return Math.max(0, Math.min(100, Math.round((clamped - tempBase) / Math.max(1, tempStep))));
    }

    function apply() {
        if (resolvedBackend.length === 0)
            return;
        if (!enabled) {
            restore();
            return;
        }
        if (resolvedBackend === "ddc")
            writeDdc(stepFor(temperature));
        else
            applyGamma();
    }

    // Neutral, not "whatever it was" - the point of turning this off is a
    // normal-looking screen.
    function restore() {
        if (resolvedBackend === "ddc" && ddcDisplays > 0) {
            if (ddcControl === "0x14" && Object.keys(presetTable ?? {}).length > 0) {
                let neutral = null;
                let bestDelta = Infinity;
                for (const k of Object.keys(presetTable)) {
                    const delta = Math.abs(parseInt(k, 10) - ddcMax);
                    if (delta < bestDelta) {
                        bestDelta = delta;
                        neutral = presetTable[k];
                    }
                }
                if (neutral !== null)
                    setForAll(["setvcp", "0x14", neutral]);
            } else {
                writeDdc(stepFor(ddcMax));
            }
        } else if (resolvedBackend === "gamma") {
            resetGamma();
        }
    }

    function writeDdc(step) {
        if (ddcControl === "0x0b") {
            expectedValue = step;
            setForAll(["setvcp", "0x0b", String(step)]);
        } else if (ddcControl === "0x14") {
            const preset = nearestPreset(temperature);
            if (preset === null) {
                writeVerified = false;
                note("no preset matches this temperature");
            } else {
                expectedValue = parseInt(String(preset).replace("0x", ""), 16);
                setForAll(["setvcp", "0x14", preset]);
            }
        } else if (ddcControl === "0x1a") {
            // Full-scale blue is neutral, lower is warmer. The 40% is a
            // heuristic: this control shifts one channel rather than setting
            // a temperature, so the Kelvin number here is a rough label.
            const ratio = Math.max(0, Math.min(1,
                (ddcMax - temperature) / Math.max(1, ddcMax - ddcMin)));
            const gain = Math.round(blueMax * (1 - ratio * 0.4));
            expectedValue = gain;
            setForAll(["setvcp", "0x1a", String(gain)]);
        }
    }

    function setForAll(args) {
        for (let i = 1; i <= ddcDisplays; i++)
            ddcSet.command = ["ddcutil", "--display", String(i)].concat(args);
        writePending = true;
        writeVerified = false;
        ddcSet.running = false;
        ddcSet.running = true;
        verifyDelay.restart();
    }

    // Read the control back and compare with what was asked for.
    function verifyDdc() {
        verifyProc.command = ["sh", "-c",
            "ddcutil --display " + probeDisplay + " getvcp " + ddcControl
            + " 2>/dev/null || true"];
        verifyProc.running = false;
        verifyProc.running = true;
    }

    function nearestPreset(kelvin) {
        const keys = Object.keys(presetTable ?? {});
        if (keys.length === 0)
            return null;
        let best = null;
        let bestDelta = Infinity;
        for (const k of keys) {
            const delta = Math.abs(parseInt(k, 10) - kelvin);
            if (delta < bestDelta) {
                bestDelta = delta;
                best = presetTable[k];
            }
        }
        return best;
    }

    // Which colour control does this display actually let us write?
    // Writability is not advertised in ddcutil's capability list - it has to
    // be found by attempting it, so this writes back the value it just read
    // (a no-op for the display) and looks at the error.
    property string probeStage: ""
    property int probeValue: 0
    property int probePreset: 0

    function probeDdcControls() {
        if (ddcDisplays <= 0) {
            ddcControl = "";
            return;
        }
        // Learn 0x0b's units from the display's own description of 0x0c
        // before using them.
        readUnits.command = ["ddcutil", "--display", "1", "getvcp", "0x0c"];
        readUnits.running = false;
        readUnits.running = true;
    }

    function readBlueMaxUnits() {
        readBlueMax.running = false;
        readBlueMax.running = true;
    }

    function probeOn(display) {
        probeDisplay = display;
        probeStage = "read0b";
        read0b.command = ["ddcutil", "--display", String(display), "getvcp", "0x0b"];
        read0b.running = false;
        read0b.running = true;
    }

    function tryWrite0b() {
        probeStage = "write0b";
        write0b.command = ["ddcutil", "--display", String(probeDisplay),
            "setvcp", "0x0b", String(probeValue)];
        write0b.running = false;
        write0b.running = true;
    }

    function tryWrite14() {
        probeStage = "write14";
        write14.command = ["ddcutil", "--display", String(probeDisplay),
            "setvcp", "0x14", String(probePreset)];
        write14.running = false;
        write14.running = true;
    }

    function finishDdcProbe(control) {
        ddcControl = control;
        probeStage = "";
        // Writes go to every display that reported the feature, so a
        // multi-monitor setup is not left with one panel warm and the rest
        // neutral.
        if (control !== "")
            writeDdc(stepFor(enabled ? temperature : ddcMax));
        if (control === "0x14" && Object.keys(presetTable ?? {}).length === 0)
            startPresetScan();
        resolve();
    }

    // Walk the preset indices and read each one's Kelvin back. This is the
    // only way to learn a monitor's preset table, it flickers the display
    // once, and the result is cached so it does not repeat.
    property int scanIndex: 0
    property var scanTable: ({})
    property int scanRestore: 0

    function startPresetScan() {
        scanningPresets = true;
        scanIndex = 0;
        scanTable = ({});
        read14Again.command = ["ddcutil", "--display", String(probeDisplay), "getvcp", "0x14"];
        read14Again.running = false;
        read14Again.running = true;
    }

    function scanNext() {
        if (scanIndex > 15) {
            const restored = scanRestore;
            scanningPresets = false;
            presetTable = scanTable;
            SettingsStore.set("nightLightPresets", JSON.stringify(scanTable));
            scanRestore = 0;
            ddcSet.command = ["ddcutil", "--display", String(probeDisplay),
                "setvcp", "0x14", String(restored)];
            ddcSet.running = false;
            ddcSet.running = true;
            apply();
            return;
        }
        // One process per step, and the read is retried in-shell.
        // ddcutil takes a flock on the I2C bus and a getvcp that loses the
        // race returns nothing at all - which silently threw away most of the
        // table the first time this ran.
        scanStep.command = ["sh", "-c",
            "ddcutil --display " + probeDisplay + " setvcp 0x14 " + scanIndex
            + " >/dev/null 2>&1; "
            + "i=0; while [ $i -lt 4 ]; do "
            + "out=$(ddcutil --display " + probeDisplay + " getvcp 0x14 2>/dev/null); "
            + "case \"$out\" in *' K (0x'*) echo \"$out\"; exit 0;; esac; "
            + "i=$((i+1)); sleep 1; done"];
        scanStep.running = false;
        scanStep.running = true;
    }

    function applyGamma() {
        stopResident.running = false;
        stopResident.running = true;
        settle.restart();
    }

    function startGamma() {
        // -P first so a second change does not stack gamma corrections.
        gammaSet.command = ["gammastep", "-P", "-O", String(Math.round(temperature))];
        gammaSet.running = false;
        gammaSet.running = true;
    }

    function resetGamma() {
        stopResident.running = false;
        stopResident.running = true;
        settleReset.restart();
    }

    function startGammaReset() {
        gammaReset.command = ["gammastep", "-x"];
        gammaReset.running = false;
        gammaReset.running = true;
    }

    Timer {
        id: settle
        interval: 350
        onTriggered: root.startGamma()
    }

    Timer {
        id: settleReset
        interval: 350
        onTriggered: root.startGammaReset()
    }

    Timer {
        id: verifyDelay
        interval: 900
        onTriggered: root.verifyDdc()
    }

    Process {
        id: verifyProc
        stdout: StdioCollector {
            onStreamFinished: {
                const text = String(this.text ?? "");
                root.writePending = false;
                if (root.ddcControl === "0x14") {
                    const m = text.match(/\(0x([0-9a-fA-F]+)\)/);
                    root.writeVerified = m !== null && parseInt(m[1], 16) === root.expectedValue;
                } else if (root.ddcControl === "0x0b") {
                    const m = text.match(/:\s*(\d+)\s*degree/);
                    root.writeVerified = m !== null && parseInt(m[1], 10) === root.expectedValue;
                } else if (root.ddcControl === "0x1a") {
                    const m = text.match(/current value\s*=\s*(\d+)/);
                    root.writeVerified = m !== null && parseInt(m[1], 10) === root.expectedValue;
                } else {
                    root.writeVerified = false;
                }
                if (!root.writeVerified)
                    root.note("the display did not accept the change");
            }
        }
    }

    function note(text) {
        const t = String(text ?? "").trim();
        if (t.length > 0)
            root.lastMessage = t.split("\n")[0];
    }

    // Does this display take a colour temperature at all? 0x0b is the
    // writable feature; its presence in the capability list is what makes a
    // display usable here. Counting the displays that have it is what lets
    // the setting say "2 displays" rather than pretending.
    Process {
        id: probeDdc

        stdout: StdioCollector {
            onStreamFinished: {
                const text = String(this.text ?? "");
                const hasFeature = /0B \(Color temperature|14 \(Select color preset|1A \(Video gain/i
                    .test(text);
                // String.matchAll is not available in this QML's JS engine.
                let displays = 0;
                const re = /Display\s+(\d+)/g;
                let m = re.exec(text);
                while (m !== null) {
                    displays = Math.max(displays, parseInt(m[1], 10));
                    m = re.exec(text);
                }
                root.ddcDisplays = hasFeature ? Math.max(1, displays) : 0;
                if (root.ddcDisplays > 0)
                    root.probeDdcControls();
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) {
                    root.ddcPresent = false;
                    root.ddcDisplays = 0;
                }
            }
        }
    }

    Process {
        id: probeGamma

        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: {
                const t = this.text.trim();
                root.gammaSupported = !/zero outputs support gamma|do not support gamma/i.test(t);
                root.note(t);
            }
        }
    }

    Process {
        id: ddcSet
        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: {
                const t = String(this.text ?? "").trim();
                root.note(t);
                if (/not writable/i.test(t) && root.ddcControl === "")
                    root.finishDdcProbe("");
            }
        }
    }

    Process {
        id: read0b
        stdout: StdioCollector {
            onStreamFinished: {
                const m = String(this.text ?? "").match(/:\s*(\d+)\s*degree/);
                if (m !== null) {
                    root.probeValue = parseInt(m[1], 10);
                    root.tryWrite0b();
                } else {
                    root.tryWrite14();
                }
            }
        }
    }

    Process {
        id: write0b
        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: {
                const t = String(this.text ?? "");
                if (/not writable/i.test(t)) {
                    // 0x0b is read-only here; try the preset control.
                    read14.command = ["ddcutil", "--display", String(probeDisplay),
                        "getvcp", "0x14"];
                    read14.running = false;
                    read14.running = true;
                } else {
                    root.finishDdcProbe("0x0b");
                }
            }
        }
    }

    Process {
        id: read14
        stdout: StdioCollector {
            onStreamFinished: {
                const m = String(this.text ?? "").match(/\(0x([0-9a-fA-F]+)\)/);
                if (m !== null) {
                    root.probePreset = parseInt(m[1], 16);
                    root.scanRestore = root.probePreset;
                    root.tryWrite14();
                } else {
                    root.finishDdcProbe("0x1a");
                }
            }
        }
    }

    Process {
        id: write14
        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: {
                const t = String(this.text ?? "");
                if (/not writable/i.test(t))
                    root.finishDdcProbe("0x1a");
                else
                    root.finishDdcProbe("0x14");
            }
        }
    }

    Process {
        id: scanStep
        stdout: StdioCollector {
            onStreamFinished: {
                const m = String(this.text ?? "").match(/(\d+)\s*K\s*\(0x([0-9a-fA-F]+)\)/);
                // Only record a preset the display actually accepted.
                // A monitor rejects presets it does not know with
                // DDCRC_VERIFY, leaving the previous preset in place - so the
                // readback still succeeds and reports the old value. Without
                // this check the walk fills the table with rejected indices
                // pointing at whatever happened to be selected, which is how
                // it "learned" one bogus entry and nothing else.
                if (m !== null && parseInt(m[2], 16) === root.scanIndex)
                    root.scanTable[m[1]] = "0x" + parseInt(m[2], 16).toString(16).padStart(2, "0");
                root.scanIndex = root.scanIndex + 1;
                root.scanNext();
            }
        }
    }

    Process {
        id: readUnits
        stdout: StdioCollector {
            onStreamFinished: {
                // e.g. "3000 + 35 * (feature 0B color temp increment)"
                const m = String(this.text ?? "").match(/(\d+)\s*\+\s*(\d+)\s*\*/);
                if (m !== null) {
                    root.tempBase = parseInt(m[1], 10);
                    root.tempStep = parseInt(m[2], 10);
                }
                root.readBlueMaxUnits();
            }
        }
    }

    Process {
        id: readBlueMax
        stdout: StdioCollector {
            onStreamFinished: {
                const m = String(this.text ?? "").match(/max value\s*=\s*(\d+)/);
                if (m !== null)
                    root.blueMax = parseInt(m[1], 10);
                root.probeOn(1);
            }
        }
        command: ["sh", "-c", "ddcutil --display 1 getvcp 0x1a 2>/dev/null || true"]
    }

    Process {
        id: read14Again
        stdout: StdioCollector {
            onStreamFinished: {
                const m = String(this.text ?? "").match(/\(0x([0-9a-fA-F]+)\)/);
                if (m !== null)
                    root.scanRestore = parseInt(m[1], 16);
                root.scanNext();
            }
        }
    }

    Process {
        id: stopResident
        command: ["pkill", "-x", "gammastep"]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    Process {
        id: gammaSet
        stdout: StdioCollector {}
        stderr: StdioCollector {
            // gammastep narrates on stderr even when nothing is wrong, so
            // this must never be read as "missing".
            onStreamFinished: {
                root.gammaSupported = !/zero outputs support gamma|do not support gamma/i
                    .test(this.text);
                root.note(this.text);
            }
        }
    }

    Process {
        id: gammaReset
        command: ["gammastep", "-x"]
        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: root.note(this.text)
        }
    }

    // Presence checks first, then the capability probe, then resolve once
    // both have reported. Resolving early would let a backend that merely
    // exists be chosen over one that is known to work.
    Process {
        id: which
        command: ["sh", "-c",
            "printf 'ddc=%s\\ngamma=%s\\n' \"$(command -v ddcutil || echo 0)\" \"$(command -v gammastep || echo 0)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const text = String(this.text ?? "");
                root.ddcPresent = /ddc=\S+/.test(text);
                root.gammaPresent = /gamma=\S+/.test(text);
                if (root.ddcPresent) {
                    probeDdc.command = ["sh", "-c", "ddcutil capabilities 2>/dev/null || true"];
                    probeDdc.running = false;
                    probeDdc.running = true;
                }
                if (root.gammaPresent) {
                    probeGamma.command = ["gammastep", "-P", "-O", "6500"];
                    probeGamma.running = false;
                    probeGamma.running = true;
                } else
                    root.gammaSupported = false;
            }
        }
    }

    Timer {
        id: resolveTimer
        interval: 1200
        onTriggered: root.resolve()
    }

    Component.onCompleted: {
        which.running = true;
        resolveTimer.restart();
    }

    IpcHandler {
        target: "nightLight"

        function setEnabled(on: bool): void {
            root.setEnabled(on);
        }

        function setTemperature(kelvin: real): void {
            root.setTemperature(kelvin);
        }

        function setBackend(value: string): void {
            root.setBackend(value);
        }

        function recheck(): void {
            root.recheck();
        }

        function state(): string {
            return JSON.stringify({
                available: root.available,
                backend: root.backend,
                resolved: root.resolvedBackend,
                ddcDisplays: root.ddcDisplays,
                ddcControl: root.ddcControl,
                tempBase: root.tempBase,
                tempStep: root.tempStep,
                blueMax: root.blueMax,
                scanning: root.scanningPresets,
                presets: root.presetTable,
                gammaSupported: root.gammaSupported,
                enabled: root.enabled,
                writeVerified: root.writeVerified,
                writePending: root.writePending,
                temperature: root.temperature,
                message: root.lastMessage
            });
        }
    }
}