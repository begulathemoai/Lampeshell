pragma Singleton

import QtQuick

Item {
    id: root

    implicitWidth: 0
    implicitHeight: 0

    property bool merged: false

    readonly property int pending: Notifs.notClosed.length
}