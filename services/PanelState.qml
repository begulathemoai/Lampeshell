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
    property string owner: ""
    property bool closing: false

    property real progress: 0

    readonly property real offsetScale: 1 - Motion.ease(
        Motion.curve(Motion.defaultSpatial), progress)
    readonly property real revealHeight: cardHeight * Motion.ease(
        Motion.curve(Motion.defaultSpatial), progress)

    property bool open: false

    readonly property bool merged: offsetScale < 1

    readonly property real travel: panelWidth + Motion.offscreenGap
    readonly property real cardOffset: travel * offsetScale

    readonly property real fillet: Layout.cornerRadius

    function setContentSize(w, h) {
        if (root.closing)
            return;
        if (panelWidth !== w)
            panelWidth = w;
        cardHeight = h;
    }

    function beginFor(panelOwner, screen, w, h) {
        if (root.owner.length > 0 && root.owner !== panelOwner
                && (root.open || root.progress > 0.001))
            return false;
        root.owner = panelOwner;
        root.screenName = screen;
        root.panelWidth = w;
        root.cardHeight = h;
        root.closing = false;
        root.open = true;
        return true;
    }

    function setContentSizeFor(panelOwner, w, h) {
        if (root.owner !== panelOwner || root.closing)
            return;
        root.setContentSize(w, h);
    }

    function closeFor(panelOwner) {
        if (root.owner !== panelOwner)
            return;
        if (root.closing && !root.open)
            return;
        root.closing = true;
        if (root.open)
            root.open = false;
        else
            root.animateTo(0);
    }

    function clearFor(panelOwner) {
        if (root.owner !== panelOwner || root.open || root.progress > 0.001)
            return;
        root.owner = "";
        root.screenName = "";
        root.panelWidth = 0;
        root.cardHeight = 0;
        root.closing = false;
    }

    function animateTo(value) {
        panelAnim.stop();
        panelAnim.from = progress;
        panelAnim.to = value;
        panelAnim.restart();
    }

    function finishTransition() {
        if (!root.closing || root.progress > 0.001)
            return;
        root.progress = 0;
        root.owner = "";
        root.screenName = "";
        root.panelWidth = 0;
        root.cardHeight = 0;
        root.closing = false;
    }

    onOpenChanged: {
        root.animateTo(open ? 1 : 0);
    }

    NumberAnimation {
        id: panelAnim
        target: root
        property: "progress"
        duration: Motion.duration(Motion.defaultSpatial)
        easing.type: Easing.Linear
        onFinished: root.finishTransition()
    }
}
