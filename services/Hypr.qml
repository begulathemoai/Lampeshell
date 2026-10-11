pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

/**
 * Single place where OctaShell talks to Hyprland's dispatcher.
 *
 * Hyprland 0.56 moved dispatchers behind a Lua API. `hyprctl dispatch workspace 1`
 * now fails with `')' expected near '1'`; it wants
 * `hyprctl dispatch 'hl.dsp.focus({ workspace = "1" })'`. Older compositors only
 * understand the flat form, so every call has to be written twice and selected
 * at runtime - which is what usingLua is for.
 *
 * Callers should use the named helpers below rather than calling
 * Hyprland.dispatch() directly, so the syntax lives in exactly one file.
 */
Singleton {
    id: root

    readonly property bool usingLua: Hyprland.usingLua

    // Raw escape hatch. `legacy` and `lua` are the same intent in each dialect.
    function dispatch(legacy: string, lua: string): void {
        Hyprland.dispatch(usingLua ? lua : legacy);
    }

    function focusWorkspace(id: int): void {
        dispatch(`workspace ${id}`, `hl.dsp.focus({ workspace = "${id}" })`);
    }

    // name is the bare special workspace, e.g. "magic" for special:magic.
    function toggleSpecialWorkspace(name: string): void {
        dispatch(`togglespecialworkspace ${name}`, `hl.dsp.workspace.toggle_special("${name}")`);
    }

    function focusMonitor(name: string): void {
        dispatch(`focusmonitor ${name}`, `hl.dsp.focus({ monitor = "${name}" })`);
    }

    // mode: 0 none, 1 maximized, 2 fullscreen.
    function setFullscreen(mode: int): void {
        dispatch(`fullscreen ${mode}`, `hl.dsp.window.fullscreen(${mode})`);
    }

    function closeWindow(address: string): void {
        const hex = address.startsWith("0x") ? address : `0x${address}`;
        dispatch(`closewindow address:${hex}`, `hl.dsp.window.close({ window = "address:${hex}" })`);
    }

    // Moves a window to a workspace. address must include the 0x prefix.
    // follow = true also focuses the window, matching Caelestia's windowinfo.
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

    //
    // bound to them silently goes stale - HyprlandWorkspace.hasFullscreen is the
    // re-read a model makes it re-emit, which is both cheaper and more accurate
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            const n = event.name;
            // The v2 variants carry the same information as their base event.
            if (n.endsWith("v2"))
                return;

            if (n === "openwindow" || n === "closewindow" || n === "movewindow") {
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
