import QtQuick
import qs.popups.nexus

Item {
    id: root

    required property var nState

    readonly property Item currentItem: currentWrapper ? currentWrapper.pageItem : null
    readonly property string currentTitle: root.currentItem ? (root.currentItem.currentTitle ?? "") : ""
    readonly property string currentDescription: root.currentItem ? (root.currentItem.currentDescription ?? "") : ""

    property Item currentWrapper: null
    property Item outgoingWrapper: null

    function createPage(idx) {
        const comp = PageCompRegistry.pageComps[idx] ?? PageCompRegistry.placeholderComp;
        const wrapper = wrapperComp.createObject(container);
        const page = comp.createObject(wrapper, {
            nState: root.nState
        });
        page.anchors.fill = wrapper;
        wrapper.pageItem = page;
        return wrapper;
    }

    function revealSetting(label) {
        const stack = root.currentItem;
        const page = stack ? stack.currentItem : null;
        if (page && typeof page.revealByLabel === "function")
            page.revealByLabel(label);
    }

    function show(idx, animate) {
        const next = createPage(idx);
        const prev = root.currentWrapper;
        root.currentWrapper = next;

        if (animate && prev) {
            if (root.outgoingWrapper) {
                root.outgoingWrapper.destroy();
                root.outgoingWrapper = null;
            }
            next.opacity = 0;
            next.scale = 0.9;
            root.outgoingWrapper = prev;
            inOpacity.target = next;
            inScale.target = next;
            outOpacity.target = prev;
            outScale.target = prev;
            switchAnim.restart();
        } else {
            next.opacity = 1;
            next.scale = 1;
            if (prev)
                prev.destroy();
        }
    }

    Component {
        id: wrapperComp

        Item {
            anchors.fill: parent
            property Item pageItem
        }
    }

    Item {
        id: container
        anchors.fill: parent
        clip: true

        Component.onCompleted: root.show(root.nState.currentPageIdx, false)
    }

    Connections {
        target: root.nState

        function onCurrentPageIdxChanged() {
            root.show(root.nState.currentPageIdx, true);
        }
    }

    ParallelAnimation {
        id: switchAnim

        NumberAnimation {
            id: inOpacity
            property: "opacity"
            to: 1
            duration: 200
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            id: inScale
            property: "scale"
            to: 1
            duration: 200
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            id: outOpacity
            property: "opacity"
            to: 0
            duration: 200
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            id: outScale
            property: "scale"
            to: 0.9
            duration: 200
            easing.type: Easing.OutCubic
        }

        onFinished: {
            if (root.outgoingWrapper) {
                root.outgoingWrapper.destroy();
                root.outgoingWrapper = null;
            }
        }
    }
}
