pragma Singleton

import QtQuick
import qs.theme

Item {
    id: root

    implicitWidth: 0
    implicitHeight: 0

    property var owner: null
    property int generation: 0
    property string phase: "closed"
    property bool open: false
    readonly property bool closing: phase === "closing"
    property real progress: 0

    readonly property bool merged: progress > 0.001

    property var pendingOwner: null
    property int pendingGeneration: 0

    signal acquired(var owner, int generation)
    signal closeRequested(var owner, int generation)
    signal released(var owner, int generation)
    signal requestCancelled(var owner)

    function claim(panelOwner, token) {
        root.generation = token === undefined ? root.generation + 1 : token;
        root.owner = panelOwner;
        root.phase = "opening";
        root.open = true;
        return root.generation;
    }

    function beginFor(panelOwner) {
        if (!panelOwner)
            return 0;

        if (root.owner === panelOwner) {
            root.pendingOwner = null;
            root.phase = "opening";
            root.open = true;
            root.animateTo(1);
            return root.generation;
        }

        if (!root.owner) {
            const token = root.claim(panelOwner);
            root.animateTo(1);
            return token;
        }

        if (root.pendingOwner && root.pendingOwner !== panelOwner)
            root.requestCancelled(root.pendingOwner);

        root.pendingOwner = panelOwner;
        root.pendingGeneration = root.generation + 1;

        if (!root.closing)
            root.closeFor(root.owner, root.generation);

        return root.pendingGeneration;
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
        root.phase = "closed";
        root.released(oldOwner, oldGeneration);

        if (root.pendingOwner) {
            const nextOwner = root.pendingOwner;
            const nextGeneration = root.pendingGeneration;
            root.pendingOwner = null;
            root.pendingGeneration = 0;
            root.claim(nextOwner, nextGeneration);
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
