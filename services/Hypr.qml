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

    property bool neutralApplied: false

    function applyOverlayRules(): void {
        const managed = SettingsStore.get("overlayEffectsManaged") === true;

        if (!managed && root.neutralApplied)
            return;
        if (managed)
            root.neutralApplied = false;

        const rule = managed
            ? `no_anim = false, blur = true, animation = "fade"`
            : `no_anim = false, blur = false, animation = "none"`;

        const namespaces = ["launcher_overlay", "clipboard_overlay", "emoji_overlay"];
        for (let i = 0; i < namespaces.length; i++) {
            const ns = namespaces[i];
            if (usingLua)
                Quickshell.execDetached(["hyprctl", "eval", `hl.layer_rule({ match = { namespace = "${ns}" }, ${rule} })`]);
            else if (managed)
                Quickshell.execDetached(["hyprctl", "keyword", `layerrule blur, 1, animation, fade, match:namespace ${ns}`]);
            else
                Quickshell.execDetached(["hyprctl", "keyword", `layerrule blur, 0, animation, none, match:namespace ${ns}`]);
        }

        if (!managed)
            root.neutralApplied = true;
    }

    onUsingLuaChanged: root.applyOverlayRules()

    Connections {
        target: SettingsStore

        function onValuesChanged(): void {
            root.applyOverlayRules();
        }
    }

    Component.onCompleted: root.applyOverlayRules()

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
