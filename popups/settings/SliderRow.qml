import QtQuick
import qs.theme

/**
 * Labelled slider row. `onMoved` reports the value while dragging so the caller
 * can push it straight to the backend; the backend clamps, so no extra range
 * handling is needed here.
 */
Item {
    id: root

    property string icon: ""
    property string label: ""
    property string suffix: "%"
    property real value: 0
    property real from: 0
    property real to: 100
    signal moved(real value)

    // Guards against feedback loops: while the user drags we echo the drag, and
    // a backend-driven change of `value` must not fight the handle.
    property bool dragging: false

    // --- Settings group chrome ---
    // group), matching Metrolist's connectedShape.
    property bool isFirst: true
    property bool isLast: true

    function setGroupShape(first, last) {
        isFirst = first;
        isLast = last;
    }

    readonly property real outerRadius: 20
    readonly property real innerRadius: 5

    Rectangle {
        id: groupSurface
        anchors.fill: parent
        z: -1
        color: Theme.surface_container
        topLeftRadius: root.isFirst ? root.outerRadius : root.innerRadius
        topRightRadius: root.isFirst ? root.outerRadius : root.innerRadius
        bottomLeftRadius: root.isLast ? root.outerRadius : root.innerRadius
        bottomRightRadius: root.isLast ? root.outerRadius : root.innerRadius
    }

    implicitHeight: 56
    width: parent ? parent.width : 0

    readonly property real shownValue: dragging ? value : value

    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            text: root.icon
            color: Theme.on_surface_variant
            font {
                family: "Material Symbols Rounded"
                pixelSize: 19
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: 92
            text: root.label
            color: Theme.on_surface
            font {
                family: "Google Sans"
                pixelSize: 13
            }
        }

        Rectangle {
            id: track
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 22 - 92 - 52 - 36
            height: 8
            radius: 4
            color: Theme.surface_container_highest

            Rectangle {
                width: track.width * ((root.value - root.from) / Math.max(1, root.to - root.from))
                height: parent.height
                radius: parent.radius
                color: Theme.primary
            }

            Rectangle {
                x: Math.max(0, Math.min(track.width - width, track.width * ((root.value - root.from) / Math.max(1, root.to - root.from)) - width / 2))
                y: (track.height - height) / 2
                width: 20
                height: 20
                radius: 10
                color: Theme.primary
                border.width: 2
                border.color: Theme.surface_container_low

                scale: dragMouse.pressed ? 1.15 : 1.0
                Behavior on scale {
                    NumberAnimation {
                        duration: 90
                    }
                }
            }

            MouseArea {
                id: dragMouse
                anchors.fill: parent
                anchors.margins: -10
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onPressed: function(event) {
                    root.dragging = true;
                    root.applyAt(event.x);
                }
                onPositionChanged: function(event) {
                    if (root.dragging)
                        root.applyAt(event.x);
                }
                onReleased: {
                    root.dragging = false;
                }

                onExited: root.dragging = false
            }

            function applyAt(px) {
                const ratio = Math.max(0, Math.min(1, px / Math.max(1, track.width)));
                const v = root.from + ratio * (root.to - root.from);
                // Echo locally so the handle tracks the pointer immediately
                root.dragging = true;
                root.moved(v);
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            horizontalAlignment: Text.AlignRight
            text: Math.round(root.value) + root.suffix
            color: Theme.on_surface_variant
            font {
                family: "Google Sans"
                pixelSize: 12
            }
        }
    }
}