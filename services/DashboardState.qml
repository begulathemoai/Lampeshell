pragma Singleton

import QtQuick

Item {
    id: root

    implicitWidth: 0
    implicitHeight: 0

    property int tab: 0

    property bool open: false

    signal closeRequested
    signal openRequested
    signal toggleRequested

    function requestClose() {
        closeRequested();
    }

    function requestOpen() {
        openRequested();
    }

    function requestToggle() {
        toggleRequested();
    }
}
