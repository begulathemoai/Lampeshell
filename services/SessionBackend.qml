import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    implicitWidth: 0
    implicitHeight: 0

    property string pending: ""
    property int confirmWindowMs: 4000

    readonly property var actions: [
        { id: "lock",     label: "Lock",        icon: "lock",              command: ["hyprlock"],                 destructive: false },
        { id: "logout",   label: "Log out",     icon: "logout",            command: ["hyprctl", "eval", "hl.dsp.exit()"], destructive: true },
        { id: "suspend",  label: "Suspend",     icon: "bedtime",           command: ["systemctl", "suspend"],     destructive: false },
        { id: "hibernate", label: "Hibernate",  icon: "ac_unit",           command: ["systemctl", "hibernate"],   destructive: true },
        { id: "reboot",   label: "Restart",     icon: "restart_alt",       command: ["systemctl", "reboot"],      destructive: true },
        { id: "poweroff", label: "Power off",   icon: "power_settings_new", command: ["systemctl", "poweroff"],   destructive: true }
    ]

    function actionById(actionId) {
        for (let i = 0; i < actions.length; i++) {
            if (actions[i].id === actionId)
                return actions[i];
        }
        return null;
    }

    function isArmed(actionId) {
        return root.pending === actionId;
    }

    function request(actionId) {
        const action = actionById(actionId);
        if (!action)
            return;

        if (!action.destructive) {
            run(actionId);
            return;
        }

        if (root.pending === actionId) {
            run(actionId);
            root.pending = "";
            return;
        }

        root.pending = actionId;
        armTimer.restart();
    }

    function cancel() {
        root.pending = "";
        armTimer.stop();
    }

    function run(actionId) {
        const action = actionById(actionId);
        if (!action)
            return;

        cancel();

        runner.command = action.command;
        runner.running = true;
    }

    Timer {
        id: armTimer
        interval: root.confirmWindowMs
        onTriggered: root.pending = ""
    }

    Process {
        id: runner
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }
}
