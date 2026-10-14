import QtQuick
import QtQuick.Controls

StackView {
    id: root

    required property var nState
    default property list<Component> pages

    readonly property string currentTitle: currentItem ? (currentItem.title ?? "") : ""
    readonly property string currentDescription: currentItem ? (currentItem.description ?? "") : ""

    function openSubPage(idx, immediate) {
        const page = pages[idx];
        if (!page) {
            console.warn("StackPage: invalid sub-page index", idx);
            nState.closeSubPage();
            return;
        }
        push(page, { nState: root.nState }, immediate ? StackView.Immediate : StackView.PushTransition);
    }

    clip: busy

    Component.onCompleted: {
        openSubPage(0, true);
        for (let i = 0; i < nState.subPageIdxStack.length; i++)
            openSubPage(nState.subPageIdxStack[i], true);
    }

    pushEnter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 200
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "scale"
                from: 0.9
                to: 1
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
    }

    pushExit: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                to: 0
                duration: 200
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "scale"
                to: 0.9
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
    }

    popEnter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 200
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "scale"
                from: 0.9
                to: 1
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
    }

    popExit: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                to: 0
                duration: 200
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "scale"
                to: 0.9
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
    }

    Connections {
        target: root.nState

        function onSubPageOpened(idx) {
            root.openSubPage(idx, false);
        }

        function onSubPageClosed() {

            if (root.depth <= 1)
                return;
            root.pop();
        }
    }
}
