import QtQuick
import QtQuick.Controls

StackView {
    id: root

    required property var nState
    default property list<Component> pages

    readonly property real animMovement: 40

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
        SequentialAnimation {
            PropertyAction {
                property: "opacity"
                value: 0
            }
            PauseAnimation {
                duration: 90
            }
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    to: 1
                    duration: 160
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "x"
                    from: root.animMovement
                    to: 0
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    pushExit: Transition {
        NumberAnimation {
            property: "opacity"
            to: 0
            duration: 110
        }
    }

    popEnter: Transition {
        SequentialAnimation {
            PropertyAction {
                property: "opacity"
                value: 0
            }
            PauseAnimation {
                duration: 90
            }
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    to: 1
                    duration: 160
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "x"
                    from: -root.animMovement
                    to: 0
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    popExit: Transition {
        NumberAnimation {
            property: "opacity"
            to: 0
            duration: 110
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
