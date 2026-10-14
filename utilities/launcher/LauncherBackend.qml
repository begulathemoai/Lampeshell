import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Item {
    id: backend

    signal openMenuRequested
    signal closeMenuRequested

    property string searchText: ""

    property string myTerminal: Quickshell.env("TERMINAL") || "xterm"

    property var actions: [
        { name: "Toggle do not disturb", description: "Suppress notification popups", icon: "notifications_off", command: "lampshell ipc notifs toggleDnd" },
        { name: "Toggle game mode", description: "Compositor effects off/on", icon: "sports_esports", command: "lampshell gamemode" },
        { name: "Toggle caffeine", description: "Keep the machine awake", icon: "local_cafe", command: "lampshell caffeine" },
        { name: "Cycle audio output", description: "Next sink (soundbar/monitor/headset)", icon: "speaker", command: "lampshell audio switch" },
        { name: "Screenshot (copy)", description: "Full screen to clipboard", icon: "screenshot_monitor", command: "lampshell screenshot --clipboard" },
        { name: "Screenshot region", description: "Pick a region, copy it", icon: "crop_free", command: "lampshell screenshot --region --clipboard" },
        { name: "Toggle recording", description: "gpu-screen-recorder on/off", icon: "fiber_manual_record", command: "lampshell record toggle" },
        { name: "Lock screen", description: "hyprlock now", icon: "lock", command: "lampshell lock" },
        { name: "Open settings", description: "Shell settings panel", icon: "settings", command: "lampshell settings" },
        { name: "Wallpapers", description: "Pick a new wallpaper", icon: "wallpaper", command: "lampshell wallpaper" },
        { name: "Clipboard history", description: "Toggle the clipboard panel", icon: "content_paste", command: "lampshell clipboard" },
        { name: "Emoji picker", description: "Toggle the emoji panel", icon: "emoji_emotions", command: "lampshell emoji" },
        { name: "Restart shell", description: "Reload Lampshell", icon: "restart_alt", command: "lampshell restart" }
    ]

    function runAction(action) {
        if (!action || !action.command)
            return;
        Quickshell.execDetached(["sh", "-c", action.command]);
        backend.closeMenuRequested();
    }

    property string calcResult: ""
    property string calcError: ""
    property bool calcPending: false

    onSearchTextChanged: {
        const expr = calcExpression();
        if (expr === "") {
            calcProc.running = false;
            calcPending = false;
            calcResult = "";
            calcError = "";
            return;
        }
        calcResult = "";
        calcError = "";
        calcDebounce.restart();
    }

    function calcExpression() {
        const t = searchText.trim();
        return t.startsWith(">calc ") ? t.slice(6).trim() : "";
    }

    Timer {
        id: calcDebounce
        interval: 250
        onTriggered: {
            const expr = backend.calcExpression();
            if (expr === "")
                return;
            backend.calcPending = true;
            calcProc.command = ["env", "LC_ALL=C", "qalc", expr];
            calcProc.running = true;
        }
    }

    Process {
        id: calcProc
        stdout: StdioCollector {
            id: calcOut
            onStreamFinished: backend.parseCalc(calcOut.text)
        }
        onExited: (exitCode, exitStatus) => {
            backend.calcPending = false;
            if (exitCode !== 0 && backend.calcResult === "" && backend.calcError === "")
                backend.calcError = "qalc failed";
        }
    }

    function parseCalc(text) {
        calcPending = false;
        const lines = (text || "").split("\n").map(l => l.trim()).filter(l => l.length > 0);
        const resultLine = lines.find(l => l.includes("=") || l.includes("≈"));
        if (!resultLine) {
            calcError = lines.length > 0 ? lines[0] : "No result";
            calcResult = "";
            return;
        }
        const idx = Math.max(resultLine.indexOf("="), resultLine.indexOf("≈"));
        calcResult = resultLine.slice(idx + 1).trim();
        calcError = "";
    }

    Process {
        id: copyProc
    }

    function copyCalcResult(item) {
        const value = item && item.result ? item.result : calcResult;
        if (!value)
            return;
        copyProc.command = ["wl-copy", value];
        copyProc.running = true;
        Toaster.toastSuccess("Copied", value, "calculate");
        backend.closeMenuRequested();
    }

    function launchApp(desktopEntry) {
        var finalCommand = [];

        finalCommand.push("uwsm");
        finalCommand.push("app");
        finalCommand.push("--");

        if (desktopEntry.runInTerminal) {
            finalCommand.push(myTerminal);
            finalCommand.push("--");
            finalCommand.push(Quickshell.shellDir + "/assets/wrap_term_launch.sh");
        }

        finalCommand = finalCommand.concat(desktopEntry.command);

        Quickshell.execDetached({
            command: finalCommand,
            workingDirectory: desktopEntry.workingDirectory
        });

        backend.closeMenuRequested();
    }

    IpcHandler {
        target: "appLauncher"
        function toggle() {
            backend.openMenuRequested();
        }
    }
}
