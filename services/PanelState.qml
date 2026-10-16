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
    property var owner: null
    readonly property var ownerObject: owner
    property int generation: 0
    property string phase: "closed"
    property bool open: false
    readonly property bool closing: phase === "closing"
    property real progress: 0

    readonly property real offsetScale: 1 - Motion.ease(
        Motion.curve(Motion.defaultSpatial), progress)
    readonly property real revealHeight: cardHeight * Motion.ease(
        Motion.curve(Motion.defaultSpatial), progress)
    readonly property bool merged: progress > 0.001
    readonly property real travel: panelWidth + Motion.offscreenGap
    readonly property real cardOffset: travel * offsetScale
    readonly property real fillet: Layout.cornerRadius

    property var pendingOwner: null
    property string pendingScreen: ""
    property real pendingWidth: 0
    property real pendingHeight: 0
    property int pendingGeneration: 0

    signal acquired(var owner, int generation)
    signal closeRequested(var owner, int generation)
    signal released(var owner, int generation)
    signal requestCancelled(var owner)

    function setContentSize(w, h) {
        if (root.closing)
            return;
        root.panelWidth = w;
        root.cardHeight = h;
    }

    function claim(panelOwner, screen, w, h, token) {
        root.generation = token === undefined ? root.generation + 1 : token;
        root.owner = panelOwner;
        root.screenName = screen;
        root.panelWidth = w;
        root.cardHeight = h;
        root.phase = "opening";
        root.open = true;
        return root.generation;
    }

    function beginFor(panelOwner, screen, w, h) {
        if (!panelOwner)
            return 0;

        if (root.owner === panelOwner) {
            root.pendingOwner = null;
            root.screenName = screen;
            if (root.closing) {
                root.generation++;
                root.panelWidth = w;
                root.cardHeight = h;
            } else {
                root.setContentSize(w, h);
            }
            root.phase = "opening";
            root.open = true;
            root.animateTo(1);
            return root.generation;
        }

        if (!root.owner) {
            const token = root.claim(panelOwner, screen, w, h);
            root.animateTo(1);
            return token;
        }

        if (root.pendingOwner && root.pendingOwner !== panelOwner)
            root.requestCancelled(root.pendingOwner);

        root.pendingOwner = panelOwner;
        root.pendingGeneration = root.generation + 1;
        root.pendingScreen = screen;
        root.pendingWidth = w;
        root.pendingHeight = h;

        if (root.phase !== "closing")
            root.closeFor(root.owner, root.generation);

        return root.pendingGeneration;
    }

    function setContentSizeFor(panelOwner, w, h) {
        if (root.owner !== panelOwner || root.closing)
            return;
        root.setContentSize(w, h);
    }

    function requestOpen(panelOwner, screen, w, h) {
        return beginFor(panelOwner, screen, w, h);
    }

    function updateFor(panelOwner, token, w, h) {
        if (root.owner !== panelOwner || root.generation !== token || root.phase !== "open")
            return false;
        root.setContentSize(w, h);
        return true;
    }

    function requestClose(panelOwner, token) {
        closeFor(panelOwner, token);
    }

    function cancelPending(panelOwner) {
        if (root.pendingOwner !== panelOwner)
            return;
        const cancelled = root.pendingOwner;
        root.pendingOwner = null;
        root.requestCancelled(cancelled);
    }

    function closeFor(panelOwner, token) {
        if (root.owner !== panelOwner || token !== root.generation || root.closing)
            return;
        root.phase = "closing";
        if (root.open)
            root.open = false;
        else
            root.animateTo(0);
    }

    function animateTo(value) {
        panelAnim.stop();
        panelAnim.from = root.progress;
        panelAnim.to = value;
        panelAnim.restart();
    }

    function finishTransition() {
        if (root.open) {
            if (root.progress >= 0.999)
                root.phase = "open";
            return;
        }

        if (root.phase !== "closing" || root.progress > 0.001)
            return;

        const oldOwner = root.owner;
        const oldGeneration = root.generation;
        root.progress = 0;
        root.owner = null;
        root.screenName = "";
        root.panelWidth = 0;
        root.cardHeight = 0;
        root.phase = "closed";
        root.released(oldOwner, oldGeneration);

        if (root.pendingOwner) {
            const nextOwner = root.pendingOwner;
            const nextScreen = root.pendingScreen;
            const nextWidth = root.pendingWidth;
            const nextHeight = root.pendingHeight;
            root.pendingOwner = null;
            root.pendingScreen = "";
            const nextGeneration = root.pendingGeneration;
            root.pendingGeneration = 0;
            root.claim(nextOwner, nextScreen, nextWidth, nextHeight, nextGeneration);
            root.animateTo(1);
            root.acquired(nextOwner, nextGeneration);
        }
    }

    onOpenChanged: {
        if (open) {
            root.phase = "opening";
            root.animateTo(1);
        } else if (root.owner) {
            root.phase = "closing";
            root.animateTo(0);
        }
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
