pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

/**
 * Wallpaper + dynamic colour, matugen style.
 *
 * Picks the accent from the wallpaper rather than from a fixed palette:
 * matugen extracts a source colour from the image, builds a Material 3 scheme
 * from it, and the resulting tokens are written straight into theme/colors.json.
 * Theme.qml watches that file, so the whole shell re-themes live.
 *
 * This replaces a `~/.local/bin/set-theme` script the wallpaper picker used to
 * shell out to, which does not exist on this machine - every wallpaper click
 * silently did nothing.
 *
 * Root is an Item, not a QtObject: quickshell 0.3.1 has no default property on
 * QtObject, so the Process children could not be attached.
 */
Item {
    id: root

    implicitWidth: 0
    implicitHeight: 0

    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string wallDir: homeDir + "/Pictures/walls"
    readonly property string colorsPath: Quickshell.shellPath("theme/colors.json")
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (homeDir + "/.local/state")) + "/octashell"

    // matugen picks the most saturated of the extracted colours. Without an
    // explicit --prefer it finds several candidates and, with no terminal
    // attached, aborts with "Failed to get source color".
    readonly property string matugenType: "scheme-smart"
    readonly property string matugenPrefer: "saturation"
    readonly property string matugenMode: "dark"

    property bool busy: false
    property string lastError: ""

    // Quickshell 0.3.1 has no FileSystemModel (Caelestia's picker needs a newer
    // Quickshell), so the listing comes from `find`. Refreshed on demand rather
    // than watched; the picker asks for a refresh whenever it opens.
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
        listProc.command = ["bash", "-c", root.listScript, "octashell-list", root.wallDir];
        listProc.running = true;
    }

    // Wallpapers sitting directly in wallDir, plus one representative per
    // subdirectory - the same shape Caelestia builds its picker from.
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

    // The applied wallpaper, taken straight from colors.json.
    // This started as a separate wallpaper.txt state file read with `cat` at
    // component completion is unreliable in this Quickshell, and a reader
    // colors.json already records wallpaper_path and Theme exposes it as a real
    // bindable property, so one file is both the theme and the wallpaper state.
    readonly property string currentWallpaper: Theme.wallpaperPath ?? ""

    readonly property bool hasWallpaper: currentWallpaper.length > 0

    /**
     * Applies a wallpaper: regenerates the colour scheme from it and records it
     * as current. The old colors.json is kept as .bak so the theme can be put
     * back the way AccentPalette.revert() expects.
     */
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

    // Colour tokens matugen emits that OctaShell does not use, and the two it
    // renamed. Everything else maps straight across.
    property string pendingWallpaper: ""

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

        // OctaShell's own token names for the two Material error tokens.
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
                // Keep whatever is already themed rather than blanking a token.
                out[key] = null;
                missing++;
            } else {
                out[key] = v;
            }
        }

        out.critical = hex("error") ?? out.critical ?? null;
        out.on_critical = hex("on_error") ?? out.on_critical ?? null;

        // response can never blank a colour. Theme's aliases are real
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

        root.backupColors();
        colorsOut.setText(JSON.stringify(out, null, 4) + "\n");
        // currentWallpaper follows colors.json through Theme, so writing it is
        root.busy = false;
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

    // --- matugen ---

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
    }

    Process {
        id: revertProc
        command: ["cp", root.colorsPath + ".bak", root.colorsPath]
        stdout: StdioCollector {}
    }

    // --- state ---

    FileView {
        id: colorsOut
        path: root.colorsPath
        printErrors: false
    }

    Component.onCompleted: root.refresh()
}
