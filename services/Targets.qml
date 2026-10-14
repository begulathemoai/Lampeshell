pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.theme

Item {
    id: root

    implicitWidth: 0
    implicitHeight: 0

    readonly property string homeDir: Quickshell.env("HOME")

    readonly property var targets: [
        {
            key: "gtk4",
            label: "GTK 4 apps",
            description: "Files, preferences and libadwaita apps",
            path: homeDir + "/.config/gtk-4.0/gtk.css"
        },
        {
            key: "gtk3",
            label: "GTK 3 apps",
            description: "Older GTK toolkits",
            path: homeDir + "/.config/gtk-3.0/gtk.css"
        }
    ]

    property bool busy: false
    property var queue: []
    property string writePath: ""
    property string writeText: ""

    FileView {
        id: gtk4File

        path: root.homeDir + "/.config/gtk-4.0/gtk.css"
        blockLoading: true
    }

    FileView {
        id: gtk3File

        path: root.homeDir + "/.config/gtk-3.0/gtk.css"
        blockLoading: true
    }

    function fileFor(key) {
        if (key === "gtk4")
            return gtk4File;
        if (key === "gtk3")
            return gtk3File;
        return null;
    }

    function target(key) {
        for (let i = 0; i < targets.length; i++) {
            if (targets[i].key === key)
                return targets[i];
        }
        return null;
    }

    function exists(key) {
        const file = fileFor(key);
        if (!file)
            return false;
        const text = file.text();
        return text !== undefined && text !== null && text.length > 0;
    }

    function enabled(key) {
        return SettingsStore.loaded && SettingsStore.get("themeTarget" + key) === true;
    }

    function hex(role) {
        const c = Theme[role];
        if (!c)
            return null;
        const s = c.toString().replace("#", "");
        return /^[0-9a-fA-F]{6}$/.test(s) ? s : null;
    }

    function gtkBlock() {
        const roles = [
            ["accent_color", "primary"],
            ["accent_fg_color", "on_primary"],
            ["accent_bg_color", "primary"],
            ["window_bg_color", "background"],
            ["window_fg_color", "on_background"],
            ["headerbar_bg_color", "surface_dim"],
            ["headerbar_fg_color", "on_surface"],
            ["popover_bg_color", "surface_dim"],
            ["popover_fg_color", "on_surface"],
            ["view_bg_color", "surface"],
            ["view_fg_color", "on_surface"],
            ["card_bg_color", "surface"],
            ["card_fg_color", "on_surface"]
        ];

        let out = "";
        for (let i = 0; i < roles.length; i++) {
            const value = root.hex(roles[i][1]);
            if (!value)
                return "";
            out += "@define-color " + roles[i][0] + " #" + value + ";\n";
        }

        out += "@define-color sidebar_bg_color @window_bg_color;\n";
        out += "@define-color sidebar_fg_color @window_fg_color;\n";
        out += "@define-color sidebar_border_color @window_bg_color;\n";
        out += "@define-color sidebar_backdrop_color @window_bg_color;\n";
        out += "@define-color theme_selected_bg_color alpha(@accent_color, 0.15);\n";
        out += "@define-color theme_selected_fg_color @primary;\n";
        return out;
    }

    function mergeGtk(existing, block) {
        if (!block || block.length === 0)
            return null;

        const defines = [];
        const rest = [];

        for (const line of existing.split("\n")) {
            if (/^@define-color\s/.test(line))
                defines.push(line);
            else
                rest.push(line);
        }

        const ours = [];
        for (const line of defines) {
            const m = /^@define-color\s+([A-Za-z0-9_]+)\s/.exec(line);
            if (m && block.includes("@define-color " + m[1] + " "))
                continue;
            ours.push(line);
        }

        const head = rest.join("\n").replace(/\s+$/, "");
        const tail = ours.join("\n");

        const parts = [block.replace(/\s+$/, "")];
        if (tail.length > 0)
            parts.push(tail);
        if (head.length > 0)
            parts.push(head);

        return parts.join("\n\n").replace(/\n{3,}/g, "\n\n") + "\n";
    }

    function apply(key) {
        const t = target(key);
        const file = fileFor(key);
        if (!t || !file)
            return;

        const existing = file.text();
        if (!existing || existing.length === 0) {
            console.warn("lampshell: no", t.path, ", refusing to create it");
            return;
        }

        const merged = mergeGtk(existing, gtkBlock());
        if (merged === null || merged === existing)
            return;

        queue.push({ path: t.path, text: merged });
        next();
    }

    function refresh() {
        if (!SettingsStore.loaded)
            return;
        for (let i = 0; i < targets.length; i++) {
            if (enabled(targets[i].key))
                apply(targets[i].key);
        }
    }

    function next() {
        if (queue.length === 0) {
            busy = false;
            return;
        }

        const item = queue.shift();
        writePath = item.path;
        writeText = item.text;

        writeProc.command = [
            "sh", "-c",
            "test -f \"$1\" || exit 0; cat > \"$1\"",
            "sh", item.path
        ];
        writeProc.running = true;
    }

    Process {
        id: writeProc

        stdinEnabled: true

        onStarted: {
            writeProc.write(root.writeText);
            writeProc.stdinEnabled = false;
        }

        onExited: root.next()
    }

    Timer {
        id: debounce

        interval: 400

        onTriggered: root.refresh()
    }

    Connections {
        target: ThemeService

        function onPaletteApplied(): void {
            debounce.restart();
        }
    }

    Connections {
        target: SettingsStore

        function onValuesChanged(): void {
            if (SettingsStore.loaded)
                debounce.restart();
        }

        function onLoadedChanged(): void {
            if (SettingsStore.loaded)
                debounce.restart();
        }
    }
}