pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: SettingsStore.get("nightLightEnabled") === true

    property real temperature: {
        const v = Number(SettingsStore.get("nightLightTemperature"));
        return isNaN(v) || v <= 0 ? 4500 : v;
    }

    property string backend: String(SettingsStore.get("nightLightBackend") ?? "auto")

    property string resolvedBackend: ""

    property bool ddcPresent: false
    property int ddcDisplays: 0
    property string ddcControl: ""
    property var presetTable: JSON.parse(String(SettingsStore.get("nightLightPresets") ?? "{}"))
    property bool scanningPresets: false

    property bool gammaPresent: false
    property bool gammaSupported: false

property real tempBase: 3000
property real tempStep: 35
property int blueMax: 65535

property int probeDisplay: 1

property string lastMessage: ""

    property bool writeVerified: false
    property bool writePending: false
    property int expectedValue: 0
    property int achievedKelvin: 0

    readonly property real ddcMin: 3000
    readonly property real ddcMax: 6500
    readonly property real gammaMin: 1000
    readonly property real gammaMax: 6500

    readonly property real minTemperature: resolvedBackend === "ddc" ? ddcMin
        : gammaMin
    readonly property real maxTemperature: 6500

    readonly property bool available: resolvedBackend.length > 0

    readonly property bool ddcUsable: ddcControl === "0x14"
        ? presetsUsable
        : (ddcControl === "0x0b" || ddcControl === "0x1a")

    property bool shaderSupported: false
    property bool shaderActive: false
    property string shaderSaved: ""

    property bool probeDdcDone: true
    property bool probeGammaDone: true
    readonly property bool probing: !probeDdcDone || !probeGammaDone

    Timer {
        id: startupProbe
        interval: 2000
        running: true
        repeat: false
        onTriggered: root.recheck()
    }

    readonly property string shaderPath: {
        const base = Quickshell.env("XDG_CACHE_HOME")
            || (Quickshell.env("HOME") + "/.cache");
        return base + "/lampshell/nightscreen-"
            + Math.round(Math.max(1000, Math.min(6500, temperature))) + ".frag";
    }

    function shaderSource() {
        const kelvin = Math.round(Math.max(1000, Math.min(6500, temperature)));
        return "#version 300 es\n"
            + "precision highp float;\n"
            + "in vec2 v_texcoord;\n"
            + "uniform sampler2D tex;\n"
            + "out vec4 fragColor;\n"
            + "const float Temperature = " + kelvin + ".0;\n"
            + "vec3 colorTemperatureToRGB(const in float temperature) {\n"
            + "    mat3 m = (temperature <= 6500.0)\n"
            + "        ? mat3(vec3(0.0, -2902.1955373783176, -8257.7997278925690),\n"
            + "               vec3(0.0, 1669.5803561666639, 2575.2827530017594),\n"
            + "               vec3(1.0, 1.3302673723350029, 1.8993753891711275))\n"
            + "        : mat3(vec3(1745.0425298314172, 1216.6168361476490, -8257.7997278925690),\n"
            + "               vec3(-2666.3474220535695, -2173.1012343082230, 2575.2827530017594),\n"
            + "               vec3(0.55995389139931482, 0.70381203140554553, 1.8993753891711275));\n"
            + "    return mix(\n"
            + "        clamp(m[0] / (vec3(clamp(temperature, 1000.0, 40000.0)) + m[1]) + m[2], 0.0, 1.0),\n"
            + "        vec3(1.0),\n"
            + "        smoothstep(1000.0, 0.0, temperature)\n"
            + "    );\n"
            + "}\n"
            + "void main() {\n"
            + "    vec4 pixColor = texture(tex, v_texcoord);\n"
            + "    vec3 color = pixColor.rgb;\n"
            + "    color = mix(color, color * colorTemperatureToRGB(Temperature), 1.0);\n"
            + "    fragColor = vec4(color, pixColor.a);\n"
            + "}\n";
    }

    FileView {
        id: shaderFile
        path: root.shaderPath
        printErrors: false
        watchChanges: false
        blockWrites: true
    }

    function applyShader() {
        if (!shaderSupported)
            return;
        if (temperature >= maxTemperature - 1) {
            clearShader();
            return;
        }
        shaderActive = true;
        shaderFile.setText(shaderSource());
        sendShader(shaderPath);
        shaderPrune.running = false;
        shaderPrune.running = true;
    }

    function sendShader(value) {
        shaderSet.command = ["hyprctl", "eval",
            "hl.config({ decoration = { screen_shader = \"" + value + "\" } })"];
        shaderSet.running = false;
        shaderSet.running = true;
    }

    Process {
        id: shaderPrune
        command: ["sh", "-c",
            "find " + shaderPath.substring(0, shaderPath.lastIndexOf("/"))
            + " -name 'nightscreen-*.frag' ! -name '"
            + shaderPath.substring(shaderPath.lastIndexOf("/") + 1)
            + "' ! -name '" + shaderSaved.substring(shaderSaved.lastIndexOf("/") + 1)
            + "' -delete 2>/dev/null; true"]
    }

    function clearShader() {
        if (shaderSaved === "") {
            finishClear("");
            return;
        }
        shaderSavedExists.running = false;
        shaderSavedExists.running = true;
    }

    Process {
        id: shaderSavedExists
        command: ["sh", "-c", "test -f \"$1\"", "_", root.shaderSaved]
        onExited: (exitCode) => root.finishClear(exitCode === 0 ? root.shaderSaved : "")
    }

    function finishClear(value) {
        sendShader(value);
        shaderActive = false;
    }

    Process {
        id: shaderSet
    }

    Process {
        id: shaderGet
        command: ["hyprctl", "getoption", "decoration:screen_shader"]

        stdout: StdioCollector {
            onStreamFinished: {
                const t = String(this.text ?? "");
                if (t.length === 0 || /no such option|unknown/i.test(t)) {
                    root.shaderSupported = false;
                    root.resolve();
                    return;
                }
                root.shaderSupported = true;
                const m = t.match(/str:\s*(.*)/);
                if (root.shaderSaved === "" && m !== null) {
                    const v = m[1].trim();
                    const clean = v === "[[EMPTY]]" ? "" : v;
                    root.shaderSaved = /nightscreen-[0-9]+\.frag$/.test(clean) ? "" : clean;
                }
                root.resolve();
            }
        }
    }

    function kelvinColor(kelvin) {
        const t = Math.max(10, Math.min(400, kelvin / 100));
        let r, g, b;
        if (t <= 66)
            r = 255;
        else
            r = 329.698727446 * Math.pow(t - 60, -0.1332047592);
        if (t <= 66)
            g = 99.4708025861 * Math.log(t) - 161.1195681661;
        else
            g = 288.1221695283 * Math.pow(t - 60, -0.0755148492);
        if (t >= 66)
            b = 255;
        else if (t <= 19)
            b = 0;
        else
            b = 138.5177312231 * Math.log(t - 10) - 305.0447927307;
        const clamp = v => Math.max(0, Math.min(255, v)) / 255;
        return Qt.rgba(clamp(r), clamp(g), clamp(b), 1);
    }

    function setEnabled(on) {
        if (enabled === on)
            return;
        enabled = on;
        SettingsStore.set("nightLightEnabled", on);
        if (resolvedBackend === "shader")
            apply();
        else
            recheck();
    }

    Timer {
        id: shaderDebounce
        interval: 180
        onTriggered: {
            if (root.enabled)
                root.applyShader();
            else
                root.clearShader();
        }
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
        restore();
        backend = b;
        SettingsStore.set("nightLightBackend", b);
        resolve();
        if (b !== "shader")
            recheck();
    }

    function recheck() {
        lastMessage = "";
        probeDdcDone = false;
        probeGammaDone = false;
        probeDdc.running = false;
        probeDdc.running = true;
        probeGamma.running = false;
        probeGamma.running = true;
        if ((backend === "auto" || backend === "shader") && !shaderSupported) {
            shaderGet.running = false;
            shaderGet.running = true;
        }
    }

    function resolve() {
        if (backend === "shader") {
            resolvedBackend = shaderSupported ? "shader" : "";
        } else if (backend === "ddc") {
            resolvedBackend = ddcDisplays > 0 && ddcUsable ? "ddc" : "";
        } else if (backend === "gamma") {
            resolvedBackend = gammaPresent && gammaSupported ? "gamma" : "";
        } else if (ddcDisplays > 0 && ddcUsable) {
            resolvedBackend = "ddc";
        } else if (gammaPresent && gammaSupported) {
            resolvedBackend = "gamma";
        } else if (shaderSupported) {
            resolvedBackend = "shader";
        } else {
            resolvedBackend = "";
        }
        apply();
    }

    readonly property string ddcLock: "/tmp/lampshell-ddc.lock"
    function ddcCall(args) {
        const inner = ["ddcutil"].concat(args).map(a => "'" + String(a).replace(/'/g, "'\\''") + "'").join(" ");
        return ["sh", "-c", "flock -w 15 " + ddcLock + " " + inner];
    }

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
        if (resolvedBackend === "shader") {
            shaderDebounce.restart();
            return;
        }
        if (resolvedBackend === "ddc")
            writeDdc(stepFor(temperature));
        else
            applyGamma();
    }

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
        } else if (resolvedBackend === "shader") {
            clearShader();
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
            const ratio = Math.max(0, Math.min(1,
                (ddcMax - temperature) / Math.max(1, ddcMax - ddcMin)));
            const gain = Math.round(blueMax * (1 - ratio * 0.4));
            expectedValue = gain;
            setForAll(["setvcp", "0x1a", String(gain)]);
        }
    }

    function setForAll(args) {
        for (let i = 1; i <= ddcDisplays; i++)
            ddcSet.command = ddcCall(["--display", String(i)].concat(args));
        writePending = true;
        writeVerified = false;
        ddcSet.running = false;
        ddcSet.running = true;
        verifyDelay.restart();
    }

    function verifyDdc() {
        verifyProc.command = ["sh", "-c",
            ddcCall(["--display", String(probeDisplay), "getvcp", ddcControl])
                .slice(2).join(" ") + " 2>/dev/null || true"];
        verifyProc.running = false;
        verifyProc.running = true;
    }

    readonly property bool presetsUsable: {
        for (const k of Object.keys(presetTable ?? {})) {
            if (parseInt(k, 10) < 6000)
                return true;
        }
        return false;
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

    property string probeStage: ""
    property int probeValue: 0
    property int probePreset: 0

    function probeDdcControls() {
        if (ddcDisplays <= 0) {
            ddcControl = "";
            return;
        }
        readUnits.command = ddcCall(["--display", "1", "getvcp", "0x0c"]);
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
        read0b.command = ddcCall(["--display", String(display), "getvcp", "0x0b"]);
        read0b.running = false;
        read0b.running = true;
    }

    function tryWrite0b() {
        probeStage = "write0b";
        write0b.command = ddcCall(["--display", String(probeDisplay),
            "setvcp", "0x0b", String(probeValue)]);
        write0b.running = false;
        write0b.running = true;
    }

    function tryWrite14() {
        probeStage = "write14";
        write14.command = ddcCall(["--display", String(probeDisplay),
            "setvcp", "0x14", String(probePreset)]);
        write14.running = false;
        write14.running = true;
    }

    function finishDdcProbe(control) {
        ddcControl = control;
        probeStage = "";
        if (control !== "")
            writeDdc(stepFor(enabled ? temperature : ddcMax));
        if (control === "0x14" && Object.keys(presetTable ?? {}).length === 0)
            startPresetScan();
        resolve();
    }

    property int scanIndex: 0
    property var scanTable: ({})
    property int scanRestore: 0

    function startPresetScan() {
        scanningPresets = true;
        scanIndex = 0;
        scanTable = ({});
        read14Again.command = ddcCall(["--display", String(probeDisplay), "getvcp", "0x14"]);
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
            ddcSet.command = ddcCall(["--display", String(probeDisplay),
                "setvcp", "0x14", String(restored)]);
            ddcSet.running = false;
            ddcSet.running = true;
            apply();
            return;
        }
        const w = ddcCall(["--display", String(probeDisplay), "setvcp", "0x14",
            String(scanIndex)]).slice(2).join(" ");
        const r = ddcCall(["--display", String(probeDisplay), "getvcp", "0x14"])
            .slice(2).join(" ");
        scanStep.command = ["sh", "-c",
            w + " >/dev/null 2>&1; "
            + "i=0; while [ $i -lt 4 ]; do "
            + "out=$(" + r + " 2>/dev/null); "
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
                    const m = text.match(/(\d+)\s*K\s*\(0x([0-9a-fA-F]+)\)/);
                    if (m !== null)
                        root.achievedKelvin = parseInt(m[1], 10);
                    root.writeVerified = m !== null && parseInt(m[2], 16) === root.expectedValue;
                } else if (root.ddcControl === "0x0b") {
                    const m = text.match(/:\s*(\d+)\s*degree/);
                    if (m !== null)
                        root.achievedKelvin = Math.round(root.tempBase
                            + parseInt(m[1], 10) * root.tempStep);
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

    Process {
        id: probeDdc

        onExited: root.probeDdcDone = true

        stdout: StdioCollector {
            onStreamFinished: {
                const text = String(this.text ?? "");
                const hasFeature = /0B \(Color temperature|14 \(Select color preset|1A \(Video gain/i
                    .test(text);
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

        onExited: root.probeGammaDone = true

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
                    read14.command = ddcCall(["--display", String(probeDisplay),
                        "getvcp", "0x14"]);
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
        command: ["sh", "-c", ddcCall(["--display", "1", "getvcp", "0x1a"]).slice(2).join(" ") + " 2>/dev/null || true"]
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

    Process {
        id: which
        command: ["sh", "-c",
            "printf 'ddc=%s\\ngamma=%s\\n' \"$(command -v ddcutil || echo 0)\" \"$(command -v gammastep || echo 0)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const text = String(this.text ?? "");
                root.ddcPresent = false;
                root.gammaPresent = /gamma=\S+/.test(text);
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
                ddcUsable: root.ddcUsable,
                shaderSupported: root.shaderSupported,
                shaderActive: root.shaderActive,
                probing: root.probing,
                ddcDisplays: root.ddcDisplays,
                ddcControl: root.ddcControl,
                achievedKelvin: root.achievedKelvin,
                presetsUsable: root.presetsUsable,
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