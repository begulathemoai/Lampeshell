pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    readonly property string flagPath: {
        const base = Quickshell.env("XDG_STATE_HOME")
            || (Quickshell.env("HOME") + "/.local/state");
        return base + "/lampshell/gamemode";
    }

    property bool enabled: false
    readonly property bool busy: false
    readonly property string lastError: ""

    FileView {
        id: flag
        path: root.flagPath
        printErrors: false

        onLoaded: {
            root.enabled = text().trim() === "1";
        }

        onLoadFailed: err => {
            if (err !== FileViewError.FileNotFound) {
                root.lastError = "could not read " + root.flagPath + ": " + err;
                return;
            }
            flag.setText("0\n");
            root.enabled = false;
        }
    }

    function setEnabled(on) {
        on = !!on;
        if (on === root.enabled)
            return;
        on = !!on;
        if (on === root.enabled)
            return;
        root.enabled = on;
        flag.setText((on ? "1" : "0") + "\n");
        Toaster.toast(on ? "Game mode on" : "Game mode off",
                      on ? "Animations, blur and shadows are off" : "Back to normal",
                      "sports_esports",
                      on ? Toaster.success : Toaster.info);
        reloadProc.command = ["hyprctl", "reload", "config-only"];
        reloadProc.running = true;
    }

    function toggle() {
        root.setEnabled(!root.enabled);
    }

    Process {
        id: reloadProc
    }

    IpcHandler {
        target: "gamemode"

        function isEnabled(): bool {
            return root.enabled;
        }

        function enable(): void {
            root.setEnabled(true);
        }

        function disable(): void {
            root.setEnabled(false);
        }

        function toggle(): void {
            root.toggle();
        }
    }
}