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
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (homeDir + "/.local/state")) + "/lampshell"

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

        onError: error => {
            root.lastError = "matugen failed to run (is it installed?)";
            root.busy = false;
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

    Component.onCompleted: root.refresh()
}
