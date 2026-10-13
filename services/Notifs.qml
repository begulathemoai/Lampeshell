pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.services

Singleton {
    id: root

    readonly property real defaultExpireTimeout: 5000
    readonly property real fullscreenExpireTimeout: 2000
    readonly property bool expire: true // auto-retract to history on timer

    property var list: []
    readonly property var notClosed: list.filter(n => !n.closed)
    readonly property var popups: list.filter(n => n.exiting || (n.popup && !n.closed))

    readonly property bool dnd: SettingsStore.get("dnd") ?? false
    function setDnd(enabled) { SettingsStore.set("dnd", !!enabled); }
    function toggleDnd() { SettingsStore.set("dnd", !dnd); }

    property var focusedMonitor: null

    property string lastError: ""
    property bool loaded: false

    readonly property string stateFile: {
        const base = Quickshell.env("XDG_STATE_HOME")
            || (Quickshell.env("HOME") + "/.local/state");
        return base + "/lampshell/notifs.json";
    }

    function hasFullscreen(monitor) {
        return FullscreenState.isFullscreen(monitor);
    }

    function shouldShowPopup() {
        if (dnd)
            return false;
        return !root.hasFullscreen(root.focusedMonitor);
    }


    NotificationServer {
        id: server

        bodyHyperlinksSupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true
        keepOnReload: false

        onNotification: notif => {
            notif.tracked = true;
            const comp = notifComp.createObject(root, {
                notification: notif,
                popup: root.shouldShowPopup()
            });
            root.list = [comp, ...root.list];
        }
    }

    Component {
        id: notifComp
        NotifData {}
    }

    FileView {
        id: storage
        path: root.stateFile
        printErrors: false
        onLoaded: {
            try {
                const data = JSON.parse(text());
                const restored = [];
                for (const n of data) {
                    if (n.notificationId === undefined && n.id !== undefined)
                        n.notificationId = n.id;
                    delete n.id;
                    restored.push(notifComp.createObject(root, n));
                }
                restored.sort((a, b) => b.time - a.time);
                root.list = restored;
            } catch (e) {
                root.lastError = "could not parse notifs.json: " + e;
            }
            root.loaded = true;
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                storage.setText("[]\n");
                root.loaded = true;
            } else {
                root.lastError = "could not read notifs.json: " + err;
                root.loaded = true;
            }
        }
    }

    Timer {
        id: saveTimer
        interval: 1000
        onTriggered: {
            const dump = root.notClosed.map(n => ({
                time: n.time,
                notificationId: n.notificationId,
                summary: n.summary,
                body: n.body,
                appIcon: n.appIcon,
                appName: n.appName,
                image: n.image,
                expireTimeout: n.expireTimeout,
                urgency: n.urgency,
                resident: n.resident,
                hasActionIcons: n.hasActionIcons,
                actions: n.actions.map(a => ({
                    identifier: a.identifier,
                    text: a.text
                }))
            }));
            storage.setText(JSON.stringify(dump, null, 2) + "\n");
        }
    }

    onListChanged: {
        if (root.loaded)
            saveTimer.restart();
    }

    IpcHandler {
        target: "notifs"

        function clear(): void {
            for (const n of root.list.slice())
                n.close();
        }

        function isDndEnabled(): bool {
            return root.dnd;
        }

        function toggleDnd(): void {
            root.toggleDnd();
        }

        function enableDnd(): void {
            root.setDnd(true);
        }

        function disableDnd(): void {
            root.setDnd(false);
        }
    }
}
