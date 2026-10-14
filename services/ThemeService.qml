pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

Item {
    id: root

    implicitWidth: 0
    implicitHeight: 0

    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string wallDir: homeDir + "/Pictures/walls"
    readonly property string colorsPath: Theme.colorsPath
    readonly property string stateBase: (Quickshell.env("XDG_STATE_HOME") || (homeDir + "/.local/state")) + "/lampshell"
    readonly property string sequencesPath: stateBase + "/sequences.txt"
    readonly property string kittyThemePath: stateBase + "/kitty-theme.conf"
    readonly property string footColorsPath: stateBase + "/foot-colors.ini"

    readonly property string matugenPrefer: "saturation"
    readonly property string matugenMode: "dark"

    property bool busy: false
    property string lastError: ""

    onBusyChanged: {
        if (busy)
            busyWatchdog.restart();
        else
            busyWatchdog.stop();
    }

    property var entries: []

    readonly property string listScript: `
set -u
dir="$1"
[ -d "$dir" ] || exit 0
find "$dir" -maxdepth 3 -type f \\
    \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\
       -o -iname '*.bmp' -o -iname '*.gif' -o -iname '*.jxl' \\) \\
    -print 2>/dev/null | LC_ALL=C sort
`

    function refresh() {
        listProc.command = ["bash", "-c", root.listScript, "lampshell-list", root.wallDir];
        listProc.running = true;
    }

    readonly property var topLevelWalls: {
        const cats = {};
        const flat = [];
        for (const w of root.entries) {
            if (w.parentDir === root.wallDir) {
                flat.push(w);
            } else {
                const cat = w.category;
                if (cat.length > 0 && !(cat in cats))
                    cats[cat] = w;
            }
        }
        return flat.concat(Object.values(cats)).sort((a, b) => a.name.localeCompare(b.name));
    }

    readonly property var categoryNames: {
        const seen = [];
        for (const w of root.entries) {
            if (w.category.length > 0 && !seen.includes(w.category))
                seen.push(w.category);
        }
        return seen.sort();
    }

    function categoryFor(entry) {
        if (!entry || entry.parentDir === root.wallDir)
            return "";
        let cat = entry.parentDir.slice(root.wallDir.length + 1);
        if (cat.includes("/"))
            cat = cat.slice(0, cat.indexOf("/"));
        return cat;
    }

    function wallsInCategory(category) {
        return root.entries
            .filter(w => w.category === category)
            .sort((a, b) => a.name.localeCompare(b.name));
    }

    function parseListing(text) {
        const base = root.wallDir;
        const out = [];
        for (const line of text.split("\n")) {
            const path = line.trim();
            if (path.length === 0)
                continue;
            const parentDir = path.slice(0, path.lastIndexOf("/"));
            out.push({
                path: path,
                name: path.slice(path.lastIndexOf("/") + 1),
                parentDir: parentDir,
                category: (() => {
                    if (parentDir === base)
                        return "";
                    let c = parentDir.slice(base.length + 1);
                    if (c.includes("/"))
                        c = c.slice(0, c.indexOf("/"));
                    return c;
                })()
            });
        }
        root.entries = out;
    }

    readonly property string currentWallpaper: Theme.wallpaperPath ?? ""

    readonly property bool hasWallpaper: currentWallpaper.length > 0

    function applyWallpaper(path) {
        if (!path || path.length === 0) {
            lastError = "no path given";
            return;
        }

        root.busy = true;
        root.lastError = "";
        root.pendingWallpaper = path;

        matugenProc.command = [
            "matugen", "image", path,
            "-j", "hex",
            "--type", root.effectiveStyleKey,
            "--prefer", root.matugenPrefer,
            "--mode", root.matugenMode,
            "--contrast", String(root.contrast),
            "--dry-run"
        ];
        matugenProc.running = true;
    }

    function revertTheme() {
        revertProc.running = true;
    }

    property string pendingWallpaper: ""
    signal paletteApplied

    property string pendingColorsJson: ""
    property string pendingAccentName: ""
    property string pendingAccentSource: ""

    readonly property var directKeys: [
        "source_color",
        "primary", "on_primary", "primary_container", "on_primary_container",
        "primary_fixed", "primary_fixed_dim", "on_primary_fixed",
        "on_primary_fixed_variant", "inverse_primary",
        "secondary", "on_secondary", "secondary_container", "on_secondary_container",
        "secondary_fixed", "secondary_fixed_dim", "on_secondary_fixed",
        "on_secondary_fixed_variant",
        "tertiary", "on_tertiary", "tertiary_container", "on_tertiary_container",
        "tertiary_fixed", "tertiary_fixed_dim", "on_tertiary_fixed",
        "on_tertiary_fixed_variant",
        "error", "on_error", "error_container", "on_error_container",
        "background", "on_background", "surface", "on_surface",
        "surface_dim", "surface_bright", "surface_tint",
        "surface_variant", "on_surface_variant",
        "inverse_surface", "inverse_on_surface",
        "surface_container_lowest", "surface_container_low", "surface_container",
        "surface_container_high", "surface_container_highest",
        "outline", "outline_variant", "shadow", "scrim"
    ];

    function shapeMatugen(colorsJson, accent, accentSource) {
        const src = colorsJson.colors ?? colorsJson;
        const hex = key => {
            const c = src[key];
            if (c === undefined || c === null)
                return null;
            if (typeof c === "string")
                return c;
            const tone = c.default ?? c.dark ?? c.light;
            return tone ? (tone.color ?? tone.hex ?? null) : null;
        };

        const out = {
            wallpaper_path: root.pendingWallpaper.length > 0 ? root.pendingWallpaper : root.currentWallpaper,
            accent: accent ?? "",
            accent_source: accentSource ?? ""
        };

        for (const key of root.directKeys) {
            const v = hex(key);
            if (v === null) {
                out[key] = null;
            } else {
                out[key] = v;
            }
        }

        if (out.primary === null)
            throw new Error("matugen returned no usable primary colour");

        root.unclipPrimary(out, accentSource ?? "");

        for (const key of Object.keys(out)) {
            if (out[key] !== null)
                continue;
            const current = Theme[key];
            if (typeof current === "string" && current.length > 0)
                out[key] = current;
        }

        return out;
    }

    readonly property var styles: [
        { key: "scheme-smart", label: "Smart" },
        { key: "scheme-tonal-spot", label: "Tonal Spot" },
        { key: "scheme-vibrant", label: "Vibrant" },
        { key: "scheme-expressive", label: "Expressive" },
        { key: "scheme-fruit-salad", label: "Fruit Salad" },
        { key: "scheme-rainbow", label: "Rainbow" },
        { key: "scheme-monochrome", label: "Monochrome" },
        { key: "scheme-neutral", label: "Neutral" },
        { key: "scheme-content", label: "Content" }
    ]

    property string styleKey: "scheme-smart"
    property real contrast: 0
    property real chromaBoost: 0
    property bool fidelity: false

    readonly property string styleLabel: {
        for (const s of root.styles) {
            if (s.key === root.effectiveStyleKey)
                return s.label;
        }
        return root.fidelity ? "Fidelity" : "Smart";
    }

    readonly property string contrastLabel: root.contrast < -0.33
        ? "Low"
        : (root.contrast > 0.33 ? "High" : "Normal")

    readonly property int chromaPercent: Math.round(Math.max(0, root.chromaBoost) * 100)

    readonly property string effectiveStyleKey: root.fidelity ? "scheme-fidelity" : root.styleKey

    function unclipPrimary(out, accentSource) {
        const src = accentSource.length > 0 ? accentSource : out.source_color;
        if (!src)
            return;

        const source = root.hexToColor(src);
        if (source.hslSaturation < 0.05)
            return;

        const primary = root.hexToColor(out.primary);
        if (primary.hslLightness <= 0.95)
            return;

        const hue = source.hslHue;
        const sat = Math.max(primary.hslSaturation, source.hslSaturation);
        out.primary = Qt.hsla(hue, sat, 0.82, 1).toString().slice(0, 7);
    }

    function loadTunables() {
        if (!SettingsStore.loaded)
            return;
        Theme.contrast = SettingsStore.get("themeContrast") ?? 0;
        Theme.chromaBoost = SettingsStore.get("themeChromaBoost") ?? 0;
        Theme.fidelity = SettingsStore.get("themeFidelity") === true;
        root.styleKey = SettingsStore.get("themeStyle") ?? "scheme-smart";
        root.contrast = SettingsStore.get("themeContrast") ?? 0;
        root.chromaBoost = SettingsStore.get("themeChromaBoost") ?? 0;
        root.fidelity = SettingsStore.get("themeFidelity") === true;
    }

    onStyleKeyChanged: if (SettingsStore.loaded)
        SettingsStore.set("themeStyle", root.styleKey)
    onContrastChanged: {
        Theme.contrast = root.contrast;
        if (SettingsStore.loaded)
            SettingsStore.set("themeContrast", root.contrast);
    }
    onChromaBoostChanged: {
        Theme.chromaBoost = root.chromaBoost;
        if (SettingsStore.loaded)
            SettingsStore.set("themeChromaBoost", root.chromaBoost);
    }
    onFidelityChanged: {
        Theme.fidelity = root.fidelity;
        if (SettingsStore.loaded)
            SettingsStore.set("themeFidelity", root.fidelity);
    }

    Connections {
        target: SettingsStore
        function onLoadedChanged() {
            if (SettingsStore.loaded)
                root.loadTunables();
        }
    }

    function regenerate(hex) {
        const source = String(hex ?? "").trim().replace(/^#/, "").toLowerCase();
        if (/^[0-9a-f]{6}$/.test(source)) {
            root.generateFromColor(source, "custom");
            return;
        }
        if (root.hasWallpaper) {
            root.applyWallpaper(root.currentWallpaper);
            return;
        }
        lastError = "nothing to regenerate: no wallpaper and no custom colour set";
    }

    function applyPalette(palette) {
        if (!palette || !palette.primary) {
            lastError = "refusing to apply a palette with no primary colour";
            return;
        }
        busy = true;
        lastError = "";
        root.pendingColorsJson = JSON.stringify(palette, null, 4) + "\n";
        root.backupColors();
    }

    function writeColors(colorsJson) {
        let out;
        try {
            out = root.shapeMatugen(colorsJson, "", "");
        } catch (e) {
            lastError = e.message ?? String(e);
            busy = false;
            return;
        }
        out.wallpaper_path = root.pendingWallpaper;
        root.applyPalette(out);
    }

    function base64(bytes) {
        const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        let out = "";
        for (let i = 0; i < bytes.length; i += 3) {
            const b0 = bytes[i];
            const b1 = bytes[i + 1];
            const b2 = bytes[i + 2];
            out += chars[b0 >> 2];
            out += chars[((b0 & 3) << 4) | ((b1 ?? 0) >> 4)];
            out += b1 === undefined ? "=" : chars[((b1 & 15) << 2) | ((b2 ?? 0) >> 6)];
            out += b2 === undefined ? "=" : chars[b2 & 63];
        }
        return out;
    }

    function generateFromColor(hex, name) {
        const cleaned = String(hex ?? "").trim().replace(/^#/, "").toLowerCase();
        if (!/^[0-9a-f]{6}$/.test(cleaned)) {
            lastError = "'" + hex + "' is not a six digit hex colour";
            return;
        }

        busy = true;
        lastError = "";
        pendingAccentName = name && name.length > 0 ? name : "custom";
        pendingAccentSource = "#" + cleaned;

        const rgb = [
            parseInt(cleaned.slice(0, 2), 16),
            parseInt(cleaned.slice(2, 4), 16),
            parseInt(cleaned.slice(4, 6), 16)
        ];

        swatchProc.command = ["sh", "-c", root.swatchScript, "lampshell-swatch",
            root.stateBase + "/swatch.ppm", root.base64(rgb)];
        swatchProc.running = true;
    }

    readonly property string swatchScript: `
set -u
out="$1"
px="$2"
dir="$(dirname "$out")"
mkdir -p "$dir" || exit 1
printf 'P6\\n1 1\\n255\\n' > "$out" || exit 1
printf '%s' "$px" | base64 -d >> "$out" || exit 1
`;

    function backupColors() {
        backupProc.command = ["cp", root.colorsPath, root.colorsPath + ".bak"];
        backupProc.running = true;
    }

    readonly property var gruvbox: [
        "282828", "cc241d", "98971a", "d79921", "458588", "b16286", "689d6a", "a89984",
        "928374", "fb4934", "b8bb26", "fabd2f", "83a598", "d3869b", "8ec07c", "ebdbb2"
    ]

    function stripHash(hex) {
        if (hex === undefined || hex === null)
            return null;
        const s = String(hex).replace("#", "").toLowerCase();
        return s.length >= 6 ? s.slice(0, 6) : null;
    }

    function hexToColor(hex) {
        const s = stripHash(hex);
        return Qt.rgba(parseInt(s.slice(0, 2), 16) / 255,
                       parseInt(s.slice(2, 4), 16) / 255,
                       parseInt(s.slice(4, 6), 16) / 255, 1);
    }

    function harmonize(fromHex, targetHex, boost) {
        const from = root.hexToColor(fromHex);
        const target = root.hexToColor(targetHex);
        const targetHue = target.hslHue < 0 ? 0 : target.hslHue * 360;
        const fromHue = from.hslHue < 0 ? targetHue : from.hslHue * 360;
        const diff = ((targetHue - fromHue + 540) % 360) - 180;
        const rotation = Math.min(Math.abs(diff) * 0.8, 100);
        const hue = (fromHue + rotation * (diff >= 0 ? 1 : -1) + 360) % 360;
        const lightness = Math.min(1, from.hslLightness * (1 + boost));
        return Qt.hsla(hue / 360, from.hslSaturation, lightness, 1).toString().replace("#", "").slice(0, 6);
    }

    function terminalPalette(primaryHex) {
        const target = stripHash(primaryHex);
        const out = [];
        for (let i = 0; i < root.gruvbox.length; i++)
            out.push(target === null ? root.gruvbox[i] : harmonize(root.gruvbox[i], target, i < 8 ? 0.35 : 0.2));
        return out;
    }

    function osc(hex, ...idx) {
        const c = stripHash(hex);
        if (c === null)
            return "";
        return "\u001b]" + idx.join(";") + ";rgb:" + c.slice(0, 2) + "/" + c.slice(2, 4) + "/" + c.slice(4, 6) + "\u001b\\";
    }

    function genSequences(p) {
        const terms = root.terminalPalette(p.primary);
        let s = "";
        s += root.osc(p.on_surface, 10);
        s += root.osc(p.surface, 11);
        s += root.osc(p.secondary, 12);
        s += root.osc(p.secondary, 17);
        for (let i = 0; i < 16; i++)
            s += root.osc(terms[i], 4, i);
        s += root.osc(p.primary, 4, 16);
        s += root.osc(p.secondary, 4, 17);
        s += root.osc(p.tertiary, 4, 18);
        return s;
    }

    function genKitty(p) {
        const terms = root.terminalPalette(p.primary);
        const sel = stripHash(p.surface_container_highest ?? p.surface_variant ?? p.surface);
        let s = "background            #" + stripHash(p.surface) + "\n";
        s += "foreground            #" + stripHash(p.on_surface) + "\n";
        s += "cursor                #" + stripHash(p.secondary) + "\n\n";
        for (let i = 0; i < 16; i++)
            s += "color" + i + "                #" + terms[i] + "\n";
        s += "\nselection_background  #" + sel + "\n";
        s += "selection_foreground  #" + stripHash(p.on_surface) + "\n";
        return s;
    }

    function genFoot(p) {
        const terms = root.terminalPalette(p.primary);
        const sel = stripHash(p.surface_container_highest ?? p.surface_variant ?? p.surface);
        let s = "[colors-dark]\n";
        s += "background=" + stripHash(p.surface) + "\n";
        s += "foreground=" + stripHash(p.on_surface) + "\n";
        s += "cursor=" + stripHash(p.on_surface) + " " + stripHash(p.secondary) + "\n";
        for (let i = 0; i < 8; i++)
            s += "regular" + i + "=" + terms[i] + "\n";
        for (let i = 0; i < 8; i++)
            s += "bright" + i + "=" + terms[i + 8] + "\n";
        s += "selection-foreground=" + stripHash(p.on_surface) + "\n";
        s += "selection-background=" + sel + "\n";
        return s;
    }

    function writeTerminal(p) {
        if (!p || !p.primary || !p.surface)
            return;
        sequencesOut.setText(root.genSequences(p));
        kittyOut.setText(root.genKitty(p));
        footOut.setText(root.genFoot(p));
    }

    function terminalFromColorsJson(text) {
        try {
            const c = JSON.parse(text);
            root.writeTerminal({
                surface: c.surface,
                on_surface: c.on_surface,
                primary: c.primary,
                secondary: c.secondary,
                tertiary: c.tertiary,
                surface_variant: c.surface_variant,
                surface_container_highest: c.surface_container_highest
            });
        } catch (e) {
            console.warn("lampshell: could not read colors.json for terminal palette:", e);
        }
    }

    IpcHandler {
        target: "wallpaper"

        function get(): string {
            return root.currentWallpaper;
        }

        function set(path: string) {
            root.applyWallpaper(path);
        }

        function list(): string {
            root.refresh();
            return root.entries.map(w => w.path).join("\n");
        }

        function categories(): string {
            return root.categoryNames.join("\n");
        }

        function revert() {
            root.revertTheme();
        }

        function palette(): string {
            const out = {};
            for (const key of root.directKeys) {
                const prop = key === "source_color" ? "sourceColor" : key;
                const resolved = Theme[prop];
                out[key] = {
                    raw: String(Theme.rawColor(key)),
                    resolved: resolved === undefined ? "" : String(resolved),
                };
            }
            out.critical = {
                raw: String(Theme.rawColor("error")),
                resolved: String(Theme.critical),
            };
            out.on_critical = {
                raw: String(Theme.rawColor("on_error")),
                resolved: String(Theme.on_critical),
            };
            return JSON.stringify(out);
        }
    }


    Process {
        id: matugenProc

        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                try {
                    root.writeColors(JSON.parse(collector.text));
                } catch (e) {
                    root.lastError = "could not parse matugen output: " + e;
                    root.busy = false;
                }
            }
        }

        stderr: StdioCollector {
            id: errCollector
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                const err = errCollector.text.trim();
                root.lastError = "matugen exited with code " + exitCode
                    + (err.length > 0 ? ": " + err
                                      : (collector.text.length > 0 ? "" : " and produced no output"));
                root.busy = false;
            }
        }
    }

    Process {
        id: swatchProc
        stdout: StdioCollector {}
        stderr: StdioCollector {
            id: swatchErr
        }

        onExited: (exitCode) => {
            if (exitCode !== 0) {
                const err = swatchErr.text.trim();
                root.lastError = "could not write the colour swatch: "
                    + (err.length > 0 ? err : "awk exited with code " + exitCode);
                root.busy = false;
                return;
            }

            accentMatugenProc.command = [
                "matugen", "image", root.stateBase + "/swatch.ppm",
                "-j", "hex",
                "--type", root.effectiveStyleKey,
                "--prefer", "saturation",
                "--mode", root.matugenMode,
                "--contrast", String(root.contrast),
                "--dry-run"
            ];
            accentMatugenProc.running = true;
        }
    }

    Process {
        id: accentMatugenProc

        stdout: StdioCollector {
            id: accentCollector
            onStreamFinished: {
                let out;
                try {
                    out = root.shapeMatugen(JSON.parse(accentCollector.text),
                        root.pendingAccentName, root.pendingAccentSource);
                } catch (e) {
                    root.lastError = "could not build a palette for that colour: "
                        + (e.message ?? String(e));
                    root.busy = false;
                    return;
                }
                root.applyPalette(out);
            }
        }

        stderr: StdioCollector {
            id: accentErr
        }

        onExited: (exitCode) => {
            if (exitCode !== 0) {
                const err = accentErr.text.trim();
                root.lastError = "matugen exited with code " + exitCode
                    + (err.length > 0 ? ": " + err : "");
                root.busy = false;
            }
        }
    }

    Process {
        id: listProc
        stdout: StdioCollector {
            id: listCollector
            onStreamFinished: root.parseListing(listCollector.text)
        }
    }

    Process {
        id: backupProc
        stdout: StdioCollector {}
        stderr: StdioCollector {
            id: backupErr
        }

        onExited: {
            const err = backupErr.text.trim();
            if (err.length > 0)
                root.lastError = "could not back up colors.json: " + err;
            if (root.pendingColorsJson.length > 0) {
                writeColorsProc.stdinEnabled = true;
                writeColorsProc.running = true;
            } else
                root.busy = false;
        }
    }

    Process {
        id: writeColorsProc
        stdinEnabled: true
        command: ["sh", "-c", "cat > '" + root.colorsPath + "'"]
        stdout: StdioCollector {}
        stderr: StdioCollector {
            id: writeErr
        }

        onStarted: {
            writeColorsProc.write(root.pendingColorsJson);
            writeColorsProc.stdinEnabled = false;
        }

        onExited: (exitCode) => {
            if (exitCode !== 0) {
                const err = writeErr.text.trim();
                root.lastError = "could not write colors.json: "
                    + (err.length > 0 ? err : "cat exited with code " + exitCode);
            }
            root.pendingColorsJson = "";
            root.busy = false;
            QtColors.sync();
            if (exitCode === 0)
                root.paletteApplied();
        }
    }

    Process {
        id: revertProc
        command: ["cp", root.colorsPath + ".bak", root.colorsPath]
        stdout: StdioCollector {}
        stderr: StdioCollector {
            id: revertErr
        }

        onExited: (exitCode) => {
            if (exitCode !== 0) {
                const err = revertErr.text.trim();
                root.lastError = "revert failed: " + (err.length > 0 ? err : "cp exited with code " + exitCode);
            } else {
                root.paletteApplied();
            }
        }
    }

    FileView {
        id: colorsWatch
        path: root.colorsPath
        printErrors: true
        watchChanges: true

        onLoaded: root.terminalFromColorsJson(text())
        onFileChanged: reload()
        onLoadFailed: (error) => root.lastError = "could not read colors.json (FileViewError " + error + ")"
    }

    FileView {
        id: sequencesOut
        path: root.sequencesPath
        printErrors: false
    }

    FileView {
        id: kittyOut
        path: root.kittyThemePath
        printErrors: false
    }

    FileView {
        id: footOut
        path: root.footColorsPath
        printErrors: false
    }

    Timer {
        id: busyWatchdog
        interval: 30000

        onTriggered: {
            if (!root.busy)
                return;
            root.busy = false;
            root.lastError = "colour generation did not finish within " + (interval / 1000) + "s";
        }
    }

    Component.onCompleted: {
        root.loadTunables();
        root.refresh();
    }
}
