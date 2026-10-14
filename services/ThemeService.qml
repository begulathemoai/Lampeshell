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
    readonly property string colorsPath: Quickshell.shellPath("theme/colors.json")
    readonly property string stateBase: (Quickshell.env("XDG_STATE_HOME") || (homeDir + "/.local/state")) + "/lampshell"
    readonly property string sequencesPath: stateBase + "/sequences.txt"
    readonly property string kittyThemePath: stateBase + "/kitty-theme.conf"
    readonly property string footColorsPath: stateBase + "/foot-colors.ini"

    readonly property string matugenType: "scheme-smart"
    readonly property string matugenPrefer: "saturation"
    readonly property string matugenMode: "dark"

    property bool busy: false
    property string lastError: ""

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
            "--type", root.matugenType,
            "--prefer", root.matugenPrefer,
            "--mode", root.matugenMode,
            "--dry-run"
        ];
        matugenProc.running = true;
    }

    function revertTheme() {
        revertProc.running = true;
    }

    property string pendingWallpaper: ""
    property string pendingColorsJson: ""

    function writeColors(colorsJson) {
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
            wallpaper_path: root.pendingWallpaper
        };

        const direct = [
            "primary", "on_primary", "primary_container", "on_primary_container",
            "secondary", "on_secondary", "secondary_container", "on_secondary_container",
            "tertiary", "on_tertiary", "tertiary_container", "on_tertiary_container",
            "background", "on_background", "surface", "on_surface",
            "surface_dim", "surface_bright",
            "surface_variant", "on_surface_variant",
            "inverse_surface", "inverse_on_surface",
            "surface_container_lowest", "surface_container_low", "surface_container",
            "surface_container_high", "surface_container_highest",
            "outline", "outline_variant", "shadow", "scrim"
        ];

        let missing = 0;
        for (const key of direct) {
            const v = hex(key);
            if (v === null) {

                out[key] = null;
                missing++;
            } else {
                out[key] = v;
            }
        }

        out.critical = hex("error") ?? out.critical ?? null;
        out.on_critical = hex("on_error") ?? out.on_critical ?? null;

        for (const key of Object.keys(out)) {
            if (out[key] !== null)
                continue;
            const current = Theme[key];
            if (typeof current === "string" && current.length > 0)
                out[key] = current;
        }

        if (out.primary === null) {
            lastError = "matugen returned no usable primary colour";
            busy = false;
            return;
        }

        root.pendingColorsJson = JSON.stringify(out, null, 4) + "\n";
        root.backupColors();
    }

    function backupColors() {
        backupProc.command = ["cp", root.colorsPath, root.colorsPath + ".bak"];
        backupProc.running = true;
    }

    // --- Terminal palette ---------------------------------------------------
    // The 16 ANSI slots start from gruvbox and are rotated towards the
    // wallpaper's primary hue so terminals always follow the shell palette.
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

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.lastError = "matugen exited with code " + exitCode + (collector.text.length > 0 ? "" : " and produced no output");
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

        // Best-effort backup: write the new palette even if the copy failed,
        // otherwise the revert snapshot would race the write (async cp) and
        // often capture the *new* colors instead of the old ones.
        onExited: {
            colorsOut.setText(root.pendingColorsJson);
            root.pendingColorsJson = "";
            root.busy = false;
            QtColors.sync();

        }
    }

    Process {
        id: revertProc
        command: ["cp", root.colorsPath + ".bak", root.colorsPath]
        stdout: StdioCollector {}
    }

    FileView {
        id: colorsOut
        path: root.colorsPath
        printErrors: false
    }

    // Regenerate the terminal palette whenever colors.json changes, so both
    // applying a wallpaper and reverting keep the terminals in sync.
    FileView {
        id: colorsWatch
        path: root.colorsPath
        printErrors: false
        watchChanges: true

        onLoaded: root.terminalFromColorsJson(text())
        onFileChanged: reload()
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

    Component.onCompleted: root.refresh()
}
