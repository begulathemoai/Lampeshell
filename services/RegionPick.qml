pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string image: ""
    property string monitor: ""

    property bool open: false
    property string state: ""

    readonly property string jobPath: {
        const base = Quickshell.env("XDG_STATE_HOME")
            || (Quickshell.env("HOME") + "/.local/state");
        return base + "/lampshell/region-job.json";
    }

    function openPicker() {
        image = "";
        monitor = "";
        state = "";
        reader.running = true;
    }

    function accept(x, y, w, h) {
        state = JSON.stringify({ x: x, y: y, w: w, h: h });
        open = false;
    }

    function cancel() {
        state = "cancelled";
        open = false;
    }

    function applyJob(text) {
        let job;
        try {
            job = JSON.parse(text);
        } catch (e) {
            state = "cancelled";
            return;
        }
        if (!job || !job.image) {
            state = "cancelled";
            return;
        }
        image = job.image;
        monitor = job.monitor || "";
        open = true;
    }

    IpcHandler {
        target: "regionPicker"

        function open() {
            root.openPicker();
        }

        function accept(x: real, y: real, w: real, h: real) {
            root.accept(x, y, w, h);
        }

        function cancel() {
            root.cancel();
        }

        function state(): string {
            return root.state;
        }
    }

    Process {
        id: reader

        command: ["cat", root.jobPath]

        stdout: StdioCollector {
            onStreamFinished: root.applyJob(this.text)
        }
    }
}