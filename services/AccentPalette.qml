pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme
import qs.services

Item {
    id: root

    implicitWidth: 0
    implicitHeight: 0

    readonly property string accentsDir: Quickshell.shellPath("theme/accents")

    property var presets: ({})

    readonly property var order: {
        const seen = [];
        for (const name of Object.keys(root.presets)) {
            if (seen.indexOf(name) < 0)
                seen.push(name);
        }
        seen.sort();
        return seen;
    }

    readonly property var swatches: root.order.map(name => ({
        name: name,
        primary: root.presets[name].primary ?? "#cfbdfe",
        on: root.presets[name].on_primary ?? "#201047",
        container: root.presets[name].primary_container ?? "#4d3d75",
        onContainer: root.presets[name].on_primary_container ?? "#e9ddff"
    }))

    readonly property string currentAccent: (Theme.accent ?? "").toLowerCase()
    readonly property bool isCustom: currentAccent === "custom"
    readonly property string currentAccentSource: {
        const raw = (Theme.accentSource ?? "").toString().trim();
        if (raw.length === 6)
            return "#" + raw;
        return raw;
    }

    readonly property int activeIndex: {
        for (let i = 0; i < root.swatches.length; i++) {
            if (root.swatches[i].name === root.currentAccent)
                return i;
        }
        return -1;
    }

    readonly property bool ready: root.order.length > 0

    property bool started: false
    property var pendingAccent: null
    property int pendingTries: 0

    Component.onCompleted: root.started = true

    Timer {
        id: retryTimer
        interval: 120
        repeat: true
        running: false

        onTriggered: {
            if (root.pendingAccent === null) {
                retryTimer.stop();
                return;
            }
            if (root.ready || root.pendingTries > 40) {
                retryTimer.stop();
                const wanted = root.pendingAccent;
                root.pendingAccent = null;
                root.pendingTries = 0;
                root.applyAccent(wanted);
                return;
            }
            root.pendingTries++;
        }
    }

    function applyAccent(nameOrIndex) {
        if (!root.ready) {
            if (root.pendingAccent === null)
                root.pendingTries = 0;
            root.pendingAccent = nameOrIndex;
            if (!retryTimer.running)
                retryTimer.restart();
            return;
        }

        const name = typeof nameOrIndex === "number"
            ? root.order[nameOrIndex]
            : String(nameOrIndex ?? "").toLowerCase();

        const preset = root.presets[name];
        if (!preset) {
            ThemeService.lastError = "unknown accent '" + name + "'";
            return;
        }

        const out = Object.assign({}, preset);
        out.accent = name;
        if (typeof out.wallpaper_path !== "string" || out.wallpaper_path.length === 0)
            out.wallpaper_path = ThemeService.currentWallpaper;

        ThemeService.applyPalette(out);
    }

    function applyCustom(hex) {
        ThemeService.generateFromColor(hex, "custom");
    }

    function revert() {
        ThemeService.revertTheme();
    }

    function parsePresets(text) {
        const out = {};
        for (const chunk of text.split(/^###/m)) {
            const trimmed = chunk.trim();
            if (trimmed.length === 0)
                continue;
            const split = trimmed.indexOf("\n");
            if (split < 0)
                continue;
            const name = trimmed.slice(0, split).trim();
            try {
                out[name] = JSON.parse(trimmed.slice(split + 1));
            } catch (e) {
                console.warn("AccentPalette: could not read accent '" + name + "':", e);
            }
        }
        root.presets = out;
    }

    Process {
        id: loadProc
        running: root.started && root.listScript.length > 0 && root.accentsDir.length > 0

        stdout: StdioCollector {
            onStreamFinished: root.parsePresets(text)
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0)
                console.warn("AccentPalette:", text.trim())
        }

        onExited: (exitCode) => {
            if (exitCode !== 0)
                ThemeService.lastError = "could not read the accent palettes in " + root.accentsDir
                    + " (exited with code " + exitCode + ")";
        }

        command: ["sh", "-c", root.listScript, "lampshell-accents", root.accentsDir]
    }

    readonly property string listScript: `
set -u
dir="$1"
[ -d "$dir" ] || exit 0
for f in "$dir"/*.json; do
    [ -e "$f" ] || continue
    printf '###%s\\n' "$(basename "$f" .json)"
    cat "$f"
    printf '\\n'
done
`
}