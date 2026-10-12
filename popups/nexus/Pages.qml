import QtQuick
import qs.popups.nexus

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
