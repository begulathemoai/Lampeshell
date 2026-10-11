import QtQuick
import QtQuick.Controls

 * Holds one section's pages as a stack, so a detail view (a network, a bluetooth
 * device) can be pushed on top of its list and popped back to.
 *
 * The stack is driven entirely by NexusState.subPageIdxStack: index 0 is always
 * the section root, and anything above it was pushed through
 * nState.openSubPage(). That keeps the visual stack and the logical stack from
 * drifting apart, which is what makes restoring state after a nav switch work.
 */
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
            // Guard against a pop arriving before its matching push, which would
            if (root.depth <= 1)
                return;
            root.pop();
        }
    }
}
