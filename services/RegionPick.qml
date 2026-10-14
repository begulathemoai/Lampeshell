pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string image: ""
    property string monitor: ""
    property bool freeze: false
    property string outPath: ""

    property bool open: false
    property string state: ""

    Timer {
        id: selfDismiss
        interval: 90000
        onTriggered: {
            if (root.open) {
                root.state = "cancelled";
                root.open = false;
            }
        }
    }

    onOpenChanged: if (open)
        selfDismiss.restart()

    readonly property string jobPath: {
        const base = Quickshell.env("XDG_STATE_HOME")
            || (Quickshell.env("HOME") + "/.local/state");
        return base + "/lampshell/region-job.json";
    }

    function openPicker() {
        image = "";
        monitor = "";
        freeze = false;
        state = "";
        reader.running = true;
    }

    function applyJob(text) {
        let job;
        try {
            job = JSON.parse(text);
        } catch (e) {
            root.state = "cancelled";
            return;
        }
        if (!job) {
            root.state = "cancelled";
            return;
        }
        image = job.image || "";
        monitor = job.monitor || "";
        freeze = job.freeze === true;
        outPath = job.out || "";
        open = true;
    }

    function finish(payload) {
        state = payload ? JSON.stringify(payload) : "cancelled";
        open = false;
    }

    function cancel() {
        state = "cancelled";
        open = false;
    }

    IpcHandler {
        target: "regionPicker"

        function open() {
            root.openPicker();
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
