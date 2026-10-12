import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

Item {
    id: root

    implicitWidth: 0
    implicitHeight: 0

    readonly property string colorsPath: Quickshell.shellPath("theme/colors.json")

    readonly property var swatches: [
        { name: "Blue",   primary: "#b4c5ff", on: "#1a2e60", container: "#324478", onContainer: "#dbe1ff" },
        { name: "Red",    primary: "#ffb4ab", on: "#690005", container: "#93000a", onContainer: "#ffdad6" },
        { name: "Violet", primary: "#d0bcff", on: "#381e72", container: "#4f378b", onContainer: "#eaddff" },
        { name: "Green",  primary: "#a6d388", on: "#1c3708", container: "#3f6b2f", onContainer: "#c1f2ab" },
        { name: "Orange", primary: "#ffb877", on: "#4a2800", container: "#8b5000", onContainer: "#ffddb6" },
        { name: "Cyan",   primary: "#83d4e5", on: "#00363f", container: "#00505c", onContainer: "#b9ecff" },
        { name: "Grey",   primary: "#c4c6d0", on: "#2f3038", container: "#44474f", onContainer: "#dde1f9" },
        { name: "Brown",  primary: "#efb8c8", on: "#4a2532", container: "#633b48", onContainer: "#ffd8e4" }
    ]

    readonly property string currentPrimary: Theme.primary.toString().toLowerCase()

    readonly property int activeIndex: {
        for (let i = 0; i < swatches.length; i++) {
            if (swatches[i].primary.toLowerCase() === currentPrimary)
                return i;
        }
        return -1;
    }

    function applyAccent(nameOrIndex) {
        let index = nameOrIndex;

        if (typeof nameOrIndex === "string") {
            index = -1;
            for (let i = 0; i < swatches.length; i++) {
                if (swatches[i].name.toLowerCase() === nameOrIndex.toLowerCase()) {
                    index = i;
                    break;
                }
            }
            if (index < 0) {
                console.warn("AccentPalette: unknown accent '" + nameOrIndex + "'");
                return;
            }
        } else {
            index = Number(index);
        }

        const swatch = swatches[index];
        if (!swatch)
            return;

        const script = `
set -eu
f="${colorsPath}"
backup="$f.bak"
[ -f "$f" ] && cp "$f" "$backup"
tmp="$(mktemp)"
sed \\
  -e 's|"primary": *"[^"]*"|"primary": "${swatch.primary}"|' \\
  -e 's|"on_primary": *"[^"]*"|"on_primary": "${swatch.on}"|' \\
  -e 's|"primary_container": *"[^"]*"|"primary_container": "${swatch.container}"|' \\
  -e 's|"on_primary_container": *"[^"]*"|"on_primary_container": "${swatch.onContainer}"|' \\
  "$f" > "$tmp"
cat "$tmp" > "$f"
rm -f "$tmp"
`;
        applyAccentProc.command = ["sh", "-c", script];
        applyAccentProc.running = true;
    }

    function revert() {
        revertProc.running = true;
    }

    Process {
        id: applyAccentProc
        stdout: StdioCollector {}
    }

    Process {
        id: revertProc
        command: ["sh", "-c", 'cp "' + root.colorsPath + '.bak" "' + root.colorsPath + '" 2>/dev/null || true']
        stdout: StdioCollector {}
    }
}
