pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.services

QtObject {
    id: notif

    property bool popup: true
    property bool closed: false

    property var locks: new Set()

    property date time: new Date()
    property int ageMins: 0
    readonly property string timeStr: {
        if (ageMins < 1)
            return "now";
        const h = Math.floor(ageMins / 60);
        const d = Math.floor(h / 24);
        if (d > 0)
            return d + "d";
        if (h > 0)
            return h + "h";
        return ageMins + "m";
    }

    property var notification

    property string notificationId: ""
    property string summary: ""
    property string body: ""
    property string appIcon: ""
    property string appName: ""
    property string image: ""
    property real expireTimeout: 0
    property int urgency: NotificationUrgency.Normal
    property bool resident: false
    property bool hasActionIcons: false
    property var actions: []

    property real defaultExpireTimeout: Notifs.defaultExpireTimeout
    property real fullscreenExpireTimeout: Notifs.fullscreenExpireTimeout

    readonly property bool hasFullscreen: {
        const m = Notifs.focusedMonitor;
        if (!m)
            return false;
        return FullscreenState.isFullscreen(m);
    }

    readonly property Timer ageTimer: Timer {
        running: !notif.closed
        repeat: true
        interval: 60000
        triggeredOnStart: true
        onTriggered: {
            const diff = Date.now() - notif.time.getTime();
            notif.ageMins = Math.floor(diff / 60000);
        }
    }

    readonly property Timer expireTimer: Timer {
        running: true
        interval: {
            if (notif.expireTimeout > 0)
                return notif.expireTimeout;
            if (notif.hasFullscreen)
                return notif.fullscreenExpireTimeout;
            return notif.defaultExpireTimeout;
        }
        onTriggered: {
            notif.popup = false;
            if (notif.expireTimer.running)
                notif.expireTimer.restart();
        }
    }

    readonly property Connections conn: Connections {
        target: notif.notification
        ignoreUnknownSignals: true

        function onClosed() { notif.close(); }
        function onSummaryChanged() { notif.summary = notif.notification.summary; }
        function onBodyChanged() { notif.body = notif.notification.body; }
        function onAppIconChanged() { notif.appIcon = notif.notification.appIcon; }
        function onAppNameChanged() { notif.appName = notif.notification.appName; }
        function onImageChanged() { notif.image = notif.notification.image; }
        function onExpireTimeoutChanged() {
            notif.expireTimeout = notif.notification.expireTimeout;
        }
        function onUrgencyChanged() { notif.urgency = notif.notification.urgency; }
        function onResidentChanged() { notif.resident = notif.notification.resident; }
        function onHasActionIconsChanged() {
            notif.hasActionIcons = notif.notification.hasActionIcons;
        }
        function onActionsChanged() {
            notif.actions = (notif.notification.actions || []).map(a => ({
                identifier: a.identifier,
                text: a.text,
                invoke: () => a.invoke()
            }));
        }
    }

    function lock(item) { locks.add(item); }
    function unlock(item) {
        locks.delete(item);
        if (closed)
            close();
    }

    function close() {
        closed = true;
        if (locks.size === 0 && Notifs.list.includes(this)) {
            Notifs.list = Notifs.list.filter(n => n !== this);
            if (notification && typeof notification.dismiss === "function")
                notification.dismiss();
            destroy();
        }
    }

    Component.onCompleted: {
        if (!notification)
            return;
        notificationId = notification.id;
        summary = notification.summary;
        body = notification.body;
        appIcon = notification.appIcon;
        appName = notification.appName;
        image = notification.image;
        expireTimeout = notification.expireTimeout;
        urgency = notification.urgency;
        resident = notification.resident;
        hasActionIcons = notification.hasActionIcons;
        actions = (notification.actions || []).map(a => ({
            identifier: a.identifier,
            text: a.text,
            invoke: () => a.invoke()
        }));
    }
}
