import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: backend

    signal openMenuRequested
    signal closeMenuRequested

    property string searchText: ""

    property string myTerminal: Quickshell.env("TERMINAL") || "xterm"

    function launchApp(desktopEntry) {
        var finalCommand = [];

        finalCommand.push("uwsm");
        finalCommand.push("app");
        finalCommand.push("--");

        if (desktopEntry.runInTerminal) {
            finalCommand.push(myTerminal);
            finalCommand.push("--");
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
