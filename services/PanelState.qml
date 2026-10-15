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
