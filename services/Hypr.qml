pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property bool usingLua: Hyprland.usingLua

    function dispatch(legacy: string, lua: string): void {
        Hyprland.dispatch(usingLua ? lua : legacy);
    }

    function focusWorkspace(id: int): void {
        dispatch(`workspace ${id}`, `hl.dsp.focus({ workspace = "${id}" })`);
    }

    function toggleSpecialWorkspace(name: string): void {
        dispatch(`togglespecialworkspace ${name}`, `hl.dsp.workspace.toggle_special("${name}")`);
    }

    function focusMonitor(name: string): void {
        dispatch(`focusmonitor ${name}`, `hl.dsp.focus({ monitor = "${name}" })`);
    }

    function setFullscreen(mode: int): void {
        dispatch(`fullscreen ${mode}`, `hl.dsp.window.fullscreen(${mode})`);
    }

    function closeWindow(address: string): void {
        const hex = address.startsWith("0x") ? address : `0x${address}`;
        dispatch(`closewindow address:${hex}`, `hl.dsp.window.close({ window = "address:${hex}" })`);
    }

    function moveWindowToWorkspace(address: string, workspace, follow: bool): void {
        const hex = address.startsWith("0x") ? address : `0x${address}`;
        const ws = String(workspace);
        dispatch(
            `movetoworkspace ${ws},address:${hex}`,
            `hl.dsp.window.move({ window = "address:${hex}", workspace = "${ws}", follow = ${follow} })`
        );
    }

    function refreshAll(): void {
        Hyprland.refreshToplevels();
        Hyprland.refreshWorkspaces();
        Hyprland.refreshMonitors();
    }

    signal configReloaded

    function applyOverlayRules(): void {
        if (!SettingsStore.loaded)
            return;
        if (SettingsStore.get("overlayEffectsManaged") !== true)
            return;

        const namespaces = [
            { ns: "launcher_overlay", blur: false },
            { ns: "clipboard_overlay", blur: false },
            { ns: "emoji_overlay", blur: false }
        ];

        for (let i = 0; i < namespaces.length; i++) {
            const entry = namespaces[i];
            const rule = `no_anim = false, blur = ${entry.blur}, animation = "fade"`;

            if (usingLua)
                Quickshell.execDetached(["hyprctl", "eval", `hl.layer_rule({ match = { namespace = "${entry.ns}" }, ${rule} })`]);
            else
                Quickshell.execDetached(["hyprctl", "keyword", `layerrule blur, ${entry.blur ? 1 : 0}, animation, fade, match:namespace ${entry.ns}`]);
        }
    }

    property var lastKeybindsManaged: undefined

    function syncKeybinds(): void {
        const want = root.keybindsManaged;
        if (want && root.lastKeybindsManaged === want)
            return;
        root.lastKeybindsManaged = want;
        root.applyKeybinds();
    }

    readonly property bool keybindsManaged: SettingsStore.loaded
        && SettingsStore.get("keybindsManaged") !== false

    readonly property var keybindDefaults: ([
        { name: "launcher", combos: ["SUPER + Space"], command: "lampshell launcher" },
        { name: "quicksettings", combos: ["SUPER + K"], command: "lampshell ipc call quickSettings toggle" },
        { name: "dashboard", combos: ["SUPER + D"], command: "lampshell ipc call dashboard toggle" },
        { name: "session", combos: ["CTRL + ALT + Delete"], command: "lampshell session" },
        { name: "lock", combos: ["SUPER + L"], command: "lampshell lock" },
        { name: "clipboard", combos: ["SUPER + V"], command: "lampshell clipboard" },
        { name: "emoji", combos: ["SUPER + Period"], command: "lampshell emoji" },
        { name: "screenshot", combos: ["Print"], command: "lampshell screenshot --region --swappy --no-clipboard", locked: true },
        { name: "screenshotFreeze", combos: ["SUPER + SHIFT + S"], command: "lampshell screenshot --freeze --swappy --no-clipboard", locked: true },
        { name: "screenshotRegion", combos: ["SUPER + ALT + S"], command: "lampshell screenshot --region", locked: true }
    ])

    readonly property var modMasks: ({
        shift: 1,
        ctrl: 4,
        alt: 8,
        super: 64
    })

    function maskFor(combo) {
        const parts = String(combo).toUpperCase().split("+").map(s => s.trim());
        let mask = 0;
        for (const part of parts) {
            if (part === "SHIFT") mask |= modMasks.shift;
            else if (part === "CTRL") mask |= modMasks.ctrl;
            else if (part === "ALT") mask |= modMasks.alt;
            else if (part === "SUPER") mask |= modMasks.super;
        }
        return mask;
    }

    function keyFor(combo) {
        const parts = String(combo).toUpperCase().split("+").map(s => s.trim());
        return parts.length > 0 ? parts[parts.length - 1].toLowerCase() : "";
    }

    function registerKeybind(entry) {
        const locked = entry.locked === true;
        for (const combo of entry.combos) {
            if (usingLua) {
                const flags = locked ? ", { locked = true }" : "";
                Quickshell.execDetached(["hyprctl", "eval",
                    `hl.bind("${combo}", hl.dsp.exec_cmd("${entry.command}")${flags})`]);
            } else {
                const extra = locked ? "l" : "";
                const parts = combo.split("+").map(p => p.trim());
                const mods = parts.slice(0, -1).join(",");
                const key = parts[parts.length - 1];
                Quickshell.execDetached(["hyprctl", "keyword",
                    `bind${extra} = ${mods}${mods.length > 0 ? "," : ""}${key}, exec, ${entry.command}`]);
            }
        }
    }

    function applyKeybinds(): void {
        if (!root.keybindsManaged)
            return;
        if (Hyprland.usingLua === undefined)
            return;
        bindDumpProc.running = true;
    }

    Process {
        id: bindDumpProc

        command: ["hyprctl", "binds", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                const taken = {};
                let parsed = [];
                try {
                    parsed = JSON.parse(text);
                } catch (e) {
                    parsed = [];
                }
                for (const bind of parsed) {
                    const m = bind.modmask ?? 0;
                    const k = String(bind.key ?? "").toLowerCase();
                    taken[`${m}:${k}`] = true;
                }
                for (const entry of root.keybindDefaults) {
                    const combo = entry.combos[0];
                    const id = `${root.maskFor(combo)}:${root.keyFor(combo)}`;
                    if (taken[id]) {
                        console.info("lampshell: " + combo + " is already bound, leaving it alone");
                        continue;
                    }
                    root.registerKeybind(entry);
                }
            }
        }
    }

    onUsingLuaChanged: root.applyOverlayRules()

    Connections {
        target: SettingsStore

        function onValuesChanged(): void {
            root.applyOverlayRules();
            root.syncKeybinds();
        }

        function onLoadedChanged(): void {
            root.applyOverlayRules();
            root.syncKeybinds();
        }
    }

    Component.onCompleted: {
        root.applyOverlayRules();
        root.syncKeybinds();
    }

    IpcHandler {
        target: "hypr"

        function focus_workspace(id: string): void {
            root.focusWorkspace(Number(id));
        }

        function toggle_special(name: string): void {
            root.toggleSpecialWorkspace(name);
        }

        function fullscreen(mode: string): void {
            root.setFullscreen(Number(mode));
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            const n = event.name;

            if (n.endsWith("v2"))
                return;

            if (n === "configreloaded") {
                root.configReloaded();
                Qt.callLater(root.applyOverlayRules);
            } else if (n === "openwindow" || n === "closewindow" || n === "movewindow") {
                Hyprland.refreshToplevels();
                Hyprland.refreshWorkspaces();
            } else if (n === "workspace" || n === "moveworkspace" || n === "focusedmon") {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshMonitors();
            } else if (n === "activespecial" || n === "deactivespecial") {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshMonitors();
            } else if (n === "fullscreen") {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshToplevels();
            } else if (n === "focusedmon" || n === "monitoradded" || n === "monitorremoved") {
                Hyprland.refreshMonitors();
            }
        }
    }
}
