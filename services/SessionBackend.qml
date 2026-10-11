import QtQuick
import Quickshell
import Quickshell.Io

 * Session actions for the logout/power menu.
 *
 * Hyprland's own exit path on this version is hl.dsp.exit(), reached through
 * `hyprctl eval`. The legacy `hyprctl dispatch exit` no longer parses: dispatch
 * arguments are Lua expressions now and expect a call, so hl.dispatch(exit)
 * raises "expected a dispatcher". Calling hl.dsp.exit() directly is the
 * supported equivalent and exits the compositor cleanly.
 *
 * Root is an Item, not a QtObject: quickshell 0.3.1 gives QtObject no default
 * property, so Process children cannot be attached to one.
 */
Item {
    id: root

    implicitWidth: 0
    implicitHeight: 0

    // Two-step confirmation state. Destructive actions must be pressed twice
    property string pending: ""
    property int confirmWindowMs: 4000

    // Actions in display order. `destructive` arms the confirmation step.
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

    // True while the given row is armed awaiting its confirming second press.
    function isArmed(actionId) {
        return root.pending === actionId;
    }

    /**
     * First call on a destructive action arms it and starts the expiry timer.
     * A second call within the window runs it. Non-destructive actions run
     * immediately. Any press on a different row re-arms that row instead.
     */
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
        // Locking keeps the session alive, so do not tear the shell down first.
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