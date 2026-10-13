pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.services

Singleton {
    id: root

    property var layouts: []
    property int activeIndex: 0

    property string deviceName: ""

    readonly property string activeLayout: {
        if (layouts.length === 0)
            return "";
        const entry = layouts[root.activeIndex];
        return entry ? entry.short : "";
    }

    readonly property bool available: layouts.length > 1

    Process {
        id: query
        command: ["sh", "-c", "hyprctl -j devices 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: root.applyOutput(this.text)
        }
    }

    function applyOutput(text) {
        let devices;
        try {
            devices = JSON.parse(text).keyboards || [];
        } catch (e) {
            return;
        }
        const real = devices.filter(d => d && d.name && !/video-bus|power-button/.test(d.name));
        if (real.length === 0)
            return;

        let chosen = real[0];
        const focused = Hyprland.focusedToplevel;
        if (focused) {
            const seat = focused.keyboard?.name;
            if (seat) {
                const match = real.find(d => d.name === seat);
                if (match)
                    chosen = match;
            }
        }

        const layouts = (chosen.layout || "").split(",").map(s => s.trim()).filter(s => s.length > 0);
        if (layouts.length === 0)
            return;

        root.deviceName = chosen.name;
        const idx = Math.max(0, Math.min(chosen.active_layout_index ?? 0, layouts.length - 1));
        const short = layouts.map(l => {
            const map = {
                "us": "US", "fr": "FR", "de": "DE", "es": "ES", "it": "IT",
                "gb": "GB", "co.uk": "UK", "pt": "PT", "nl": "NL", "se": "SE",
                "no": "NO", "dk": "DK", "fi": "FI", "pl": "PL", "cz": "CZ",
                "ch": "CH", "be": "BE", "ca": "CA", "jp": "JP", "cn": "CN",
                "ru": "RU", "ua": "UA", "tr": "TR", "br": "BR"
            };
            return map[l.toLowerCase()] || l.toUpperCase().slice(0, 3);
        });
        root.layouts = short.map((s, i) => ({ short: s, index: i }));
        root.activeIndex = idx;
    }

    function refresh() {
        query.running = true;
    }

    function cycle() {
        if (!root.available)
            return;
        const next = (root.activeIndex + 1) % root.layouts.length;
        switchProc.command = ["hyprctl", "switchxkblayout", root.deviceName, String(next)];
        switchProc.running = true;
    }

    function setIndex(index) {
        if (index < 0 || index >= root.layouts.length || index === root.activeIndex)
            return;
        switchProc.command = ["hyprctl", "switchxkblayout", root.deviceName, String(index)];
        switchProc.running = true;
    }

    Process {
        id: switchProc
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const n = String(event.name);
            if (n === "activelayout" || n === "activelayoutv2" || n === "focuswindow" || n === "focuswindowv2")
                Qt.callLater(root.refresh);
        }
    }

    Component.onCompleted: refresh()

    IpcHandler {
        target: "kblayout"

        function current(): string {
            return root.activeLayout;
        }

        function cycle(): void {
            root.cycle();
        }

        function set(index: int): void {
            root.setIndex(index);
        }

        function list(): string {
            return root.layouts.map(l => l.short).join("\n");
        }
    }
}