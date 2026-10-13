pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int pollIntervalMs: 5000
    readonly property real nudgeStep: 0.05

    readonly property string ddcLock: "/tmp/lampshell-ddc.lock"

    function ddc(args) {
        return "flock -w 15 " + ddcLock + " " + args;
    }

    property int bus: -1
    property real level: 0.0
    property string lastError: ""
    property bool available: false
    property string displayModel: ""

    Process {
        id: detectProc
        command: ["sh", "-c", ddc("ddcutil detect --brief") + " 2>/dev/null || true"]
        running: true
        stdout: StdioCollector {
            id: detectCollector
            onStreamFinished: {
                const out = detectCollector.text;
                const m = out.match(/I2C bus:\s+\/dev\/i2c-(\d+)/);
                const nameMatch = out.match(/Monitor:\s+(.+)$/m);
                if (m) {
                    root.bus = parseInt(m[1]);
                    root.displayModel = nameMatch ? nameMatch[1].trim() : "";
                    root.available = true;
                    root.refresh();
                } else {
                    root.lastError = "no DDC display found (is ddcutil installed?)";
                    root.available = false;
                }
            }
        }
    }

    Timer {
        id: settleTimer
        interval: 2000
    }

    Timer {
        interval: root.pollIntervalMs
        repeat: true
        running: root.available && !settleTimer.running
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    function refresh() {
        if (bus < 0)
            return;
        queryProc.command = ["sh", "-c", ddc("ddcutil --bus " + root.bus + " getvcp 10") + " 2>/dev/null || true"];
        queryProc.running = true;
    }

    Process {
        id: queryProc
        stdout: StdioCollector {
            id: queryCollector
            onStreamFinished: {
                const m = queryCollector.text.match(/current value =\s*(\d+)/);
                if (!m)
                    return;
                const cur = parseInt(m[1]);
                if (isNaN(cur))
                    return;
                root.level = cur / 100.0;
            }
        }
    }

    function setLevel(fraction) {
        if (bus < 0)
            return;
        const pct = Math.round(Math.max(0, Math.min(1, fraction)) * 100);
        level = pct / 100.0;
        settleTimer.restart();
        setterProc.command = ["sh", "-c", ddc("ddcutil --bus " + root.bus + " setvcp 10 " + pct) + " 2>&1 || true"];
        setterProc.running = true;
    }

    function nudge(delta) {
        setLevel(level + delta);
    }

    Process {
        id: setterProc
        stdout: StdioCollector {
            id: setterCollector
            onStreamFinished: {
                const out = setterCollector.text.trim();
                if (out.length > 0 && out.indexOf("DDC communication failed") >= 0)
                    root.lastError = out;
            }
        }
    }

    IpcHandler {
        target: "brightness"

        function get(): real {
            return root.level;
        }
        function set(value: string): string {
            root.setLevel(parseFloat(value));
            return String(root.level);
        }
        function up(): void {
            root.nudge(root.nudgeStep);
        }
        function down(): void {
            root.nudge(-root.nudgeStep);
        }
    }
}
