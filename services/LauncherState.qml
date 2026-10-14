pragma Singleton

import QtQuick
import qs.theme

// State for the bottom-centre launcher. Mirrors DashboardState (the top-centre
// dashboard) so bar/Chrome.qml can cut a matching notch out of the bottom
// bezel: the reveal grows the notch upwards from the bottom bar, the opposite
// of the dashboard's downward notch.
Item {
    id: root

    implicitWidth: 0
    implicitHeight: 0

    property real panelWidth: 0
    property real cardHeight: 0

    // Which screen the window is on; the painted notch only goes there.
    property string screenName: ""

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

    property real progress: 0
    property bool open: false

    // The reveal grows the merged notch upwards from the bottom bar.
    readonly property real eased: Motion.ease(Motion.curve(Motion.defaultSpatial), progress)
    readonly property real revealHeight: cardHeight * eased
    readonly property bool merged: progress > 0.001

    function setContentSize(w, h) {
        if (panelWidth !== w)
            panelWidth = w;
        if (cardHeight !== h)
            cardHeight = h;
    }

    onOpenChanged: {
        panelAnim.from = progress;
        panelAnim.to = open ? 1 : 0;
        panelAnim.restart();
    }

    NumberAnimation {
        id: panelAnim
        target: root
        property: "progress"
        duration: Motion.duration(Motion.defaultSpatial)
        easing.type: Easing.Linear
    }
}
