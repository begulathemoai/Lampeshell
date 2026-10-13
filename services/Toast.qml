import QtQuick
import qs.services

QtObject {
    id: toast

    property string title
    property string message
    property string icon
    property int type
    property int timeoutMs: 3000

    property var locks: []
    property bool closed: false

    readonly property Timer lifetime: Timer {
        interval: toast.timeoutMs
        running: !toast.closed
        onTriggered: toast.closed = true
    }

    function lock(item) {
        if (!toast.locks.includes(item))
            toast.locks = [...toast.locks, item];
    }

    function unlock(item) {
        if (!toast.locks.includes(item))
            return;
        toast.locks = toast.locks.filter(x => x !== item);
        if (toast.closed && toast.locks.length === 0)
            removeSelf();
    }

    function close() {
        toast.closed = true;
        if (toast.locks.length === 0)
            removeSelf();
    }

    function removeSelf() {
        Qt.callLater(() => Toaster.remove(toast));
    }
}