pragma Singleton

import QtQuick
import qs.theme

Item {
    id: root

    implicitWidth: 0
    implicitHeight: 0


    property real panelWidth: 0
    readonly property real leftInset: Layout.s(18)
    property real cardHeight: 0

    // Which screen the panel window is actually on. The painted card only
    // goes there: bar/Chrome.qml runs once per screen, so without this
    // every screen gets a copy of the card sized to itself, which on a
    // mixed-setup desktop is a panel-shaped slab floating over a monitor
    // that has no panel on it.
    property string screenName: ""

    property real progress: 0

    readonly property real offsetScale: 1 - Motion.ease(
        Motion.curve(Motion.defaultSpatial), progress)

    property bool open: false

    readonly property bool merged: offsetScale < 1

    readonly property real travel: panelWidth + Motion.offscreenGap
    readonly property real cardOffset: travel * offsetScale

    readonly property real fillet: Layout.cornerRadius

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
