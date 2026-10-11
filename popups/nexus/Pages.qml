import QtQuick
import qs.popups.nexus

/**
 * Hosts exactly one section at a time.
 *
 * The previous page is destroyed rather than hidden. Six always-live page trees
 * meant every one of them kept its bindings, timers and Repeaters alive while
 * off-screen; destroying them also means a page cannot go stale while it is not
 * the visible one.
 */
Item {
    id: root

    required property var nState

    property Item currentItem: null

    function loadPage(idx) {
        if (currentItem) {
            currentItem.destroy();
            currentItem = null;
        }

        const comp = PageCompRegistry.pageComps[idx] ?? PageCompRegistry.placeholderComp;
        const incubator = comp.incubateObject(container, { nState: root.nState });

        const attach = () => {
            incubator.object.anchors.fill = container;
            currentItem = incubator.object;
        };

        if (incubator.status === Component.Ready) {
            attach();
        } else {
            incubator.onStatusChanged = status => {
                if (status === Component.Ready)
                    attach();
            };
        }
    }

    Item {
        id: container
        anchors.fill: parent

        Component.onCompleted: root.loadPage(root.nState.currentPageIdx)
    }

    Connections {
        target: root.nState

        function onCurrentPageIdxChanged() {
            // Fade out, swap, fade back in. The direction alternates so moving
            // down the list feels like moving forward.
            root.animOff = root.nState.currentPageIdx > root.lastPageIdx ? 1 : -1;
            switchAnim.start();
            root.lastPageIdx = root.nState.currentPageIdx;
        }
    }

    property int animOff: 1
    property int lastPageIdx: 0

    SequentialAnimation {
        id: switchAnim

        NumberAnimation {
            target: container
            property: "opacity"
            to: 0
            duration: 90
        }
        ScriptAction {
            script: root.loadPage(root.nState.currentPageIdx)
        }
        NumberAnimation {
            target: container
            property: "opacity"
            to: 1
            duration: 150
            easing.type: Easing.OutCubic
        }
    }
}
