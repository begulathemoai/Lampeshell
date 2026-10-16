pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.services

QtObject {
    id: notif

    property bool popup: false
    property bool closed: false

    property bool exiting: false
    property var popupLeaseOwner: null

    property var locks: []

    property date time: new Date()
    readonly property real timeMs: {
        const t = notif.time;
        if (t instanceof Date)
            return t.getTime();
        const parsed = Date.parse(t);
        return isNaN(parsed) ? Date.now() : parsed;
    }
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
    property real expireTimeout: -1
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
            const diff = Date.now() - notif.timeMs;
            notif.ageMins = Math.max(0, Math.floor(diff / 60000));
        }
    }

    readonly property Timer expireTimer: Timer {
        onTriggered: notif.retract();
    }

    function retract() {
        if (exiting)
            return;
        exiting = true;
        popup = false;
    }

    function computeInterval() {
        if (notif.expireTimeout > 0)
            return notif.expireTimeout;
        if (notif.expireTimeout === 0 || notif.resident)
            return -1;
        if (notif.hasFullscreen)
            return notif.fullscreenExpireTimeout;
        return notif.defaultExpireTimeout;
    }

    function scheduleExpire() {
        const ms = computeInterval();
        if (ms < 0 || (!Notifs.expire && !notif.hasFullscreen)) {
            expireTimer.stop();
            return;
        }
        expireTimer.interval = ms;
        expireTimer.restart();
    }

    function pauseExpire() {
        expireTimer.stop();
    }

    function resumeExpire() {
        if (!closed && popup)
            scheduleExpire();
    }

    readonly property Connections conn: Connections {
        target: notif.notification ?? null
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

    function lock(item) {
        if (!locks.includes(item))
            locks = [...locks, item];
    }

    function unlock(item) {
        if (!locks.includes(item))
            return;
        locks = locks.filter(x => x !== item);
        if (closed)
            close();
    }

    function close() {
        closed = true;
        if (locks.length > 0) {
            exiting = true;
            return;
        }
        notif.removeTimer.restart();
    }

    readonly property Timer removeTimer: Timer {
        interval: 0
        onTriggered: {
            if (locks.length > 0 || closed === false)
                return;
            if (!Notifs.list.includes(notif))
                return;
            Notifs.list = Notifs.list.filter(n => n !== notif);
            if (notif.notification && !notif.notification.closed
                    && typeof notif.notification.dismiss === "function")
                notif.notification.dismiss();
            notif.destroy();
        }
    }

    function endExit() {
        if (!exiting)
            return;
        exiting = false;
        if (closed)
            close();
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
        if (popup)
            scheduleExpire();
    }
}
