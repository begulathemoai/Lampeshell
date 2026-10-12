pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.theme

Singleton {
    id: root

    readonly property int pollIntervalMs: 2000
    readonly property real nudgeStep: 0.05 // matches Caelestia's 5%

    property int bus: -1
    property real level: 0.0
    property real lastSetLevel: -1.0
    property string lastError: ""
    property bool available: false

    readonly property string _displayModel: {
        const out = detectProc.text;
        for (const line of out.split("\n")) {
            const m = line.match(/Monitor:\s+(.+)$/);
            if (m) return m[1].trim();
        }
        return "";
    }

    Process {
        id: detectProc
        command: ["ddcutil", "detect", "--brief"]
        stdout: StdioCollector {}
        onExited: {
            const out = detectProc.text;
            const m = out.match(/I2C bus:\s+\/dev\/i2c-(\d+)/);
            if (m) {
                root.bus = parseInt(m[1]);
                root.available = true;
                root.refresh();
            } else {
                root.lastError = "no DDC display found";
                root.available = false;
            }
        }
        onErrorOccurred: {
            root.lastError = "ddcutil not available (is it installed?)";
        }
    }

    Component.onCompleted: {
        if (available)
            refresh();
    }

    Timer {
        interval: root.pollIntervalMs
        repeat: true
        running: root.available
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    function refresh() {
        if (bus < 0) return;
        queryProc.command = ["ddcutil", "--bus", String(bus), "getvcp", "10"];
        queryProc.running = true;
    }

    Process {
        id: queryProc
        stdout: StdioCollector {}
        onExited: {
            if (queryProc.exitCode !== 0) return;
            const m = queryProc.text.match(/VCP 10 [CL] (\d+)/);
            if (!m) return;
            const cur = parseInt(m[1]);
            if (isNaN(cur)) return;
            const newLevel = cur / 100.0;
            if (Math.abs(newLevel - root.lastSetLevel) > 0.001) {
                root.level = newLevel;
            } else if (Math.abs(newLevel - root.level) > 0.001) {
                root.level = newLevel;
            }
        }
    }

    function setLevel(fraction) {
        if (bus < 0) return;
        const pct = Math.round(Math.max(0, Math.min(1, fraction)) * 100);
        level = pct / 100.0;
        lastSetLevel = level;
        setterProc.command = ["ddcutil", "--bus", String(bus), "setvcp", "10", String(pct)];
        setterProc.running = true;
    }

    function nudge(delta) {
        setLevel(level + delta);
    }

    Process {
        id: setterProc
        stdout: StdioCollector {}
        onExited: {
            if (setterProc.exitCode !== 0)
                root.lastError = "ddcutil setvcp failed: " + setterProc.text.trim();
        }
    }

    IpcHandler {
        target: "brightness"

        function get(): real { return root.level; }
        function set(value: string): string { root.setLevel(parseFloat(value)); return String(root.level); }
        function up(): void { root.nudge(root.nudgeStep); }
        function down(): void { root.nudge(-root.nudgeStep); }
    }
}
