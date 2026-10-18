import QtQuick
import qs.theme

Item {
    id: root

    property string icon: "volume_up"
    property real value: 0.0
    property string suffix: "%"
    property bool moving: false

    readonly property bool showValue: moving || mouse.pressed

    signal moved(real value)

    implicitWidth: 200
    implicitHeight: 34

    readonly property real handleSize: height
    readonly property real maxX: Math.max(0, width - handleSize)
    readonly property real handleX: Math.max(0, Math.min(maxX, value * maxX))

    Rectangle {
        id: track

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        radius: 12
        color: Theme.surface_container_high
    }

    Rectangle {
        id: fill

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        width: root.handleX + root.handleSize / 2
        radius: 12
        color: Theme.secondary

        Behavior on width {
            enabled: !mouse.pressed
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        id: handle

        anchors.verticalCenter: parent.verticalCenter
        x: root.handleX
        width: root.handleSize
        height: root.handleSize
        radius: 12
        color: Theme.inverse_surface
        scale: mouse.pressed ? 1.06 : 1.0

        Behavior on scale {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
        Behavior on x {
            enabled: !mouse.pressed
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Text {
            anchors.centerIn: parent
            text: root.showValue ? Math.round(root.value * 100) + root.suffix : root.icon
            color: Theme.inverse_on_surface
            font {
                family: root.showValue ? "Google Sans" : "Material Symbols Rounded"
                pixelSize: root.showValue ? 13 : 18
                weight: root.showValue ? Font.Bold : Font.Normal
            }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        function fractionAt(mx) {
            const span = root.width - root.handleSize;
            if (span <= 0)
                return 0;
            return Math.max(0, Math.min(1, (mx - root.handleSize / 2) / span));
        }

        onPressed: mouse => {
            root.moving = true;
            root.moved(fractionAt(mouse.x));
        }
        onPositionChanged: mouse => {
            if (pressed)
                root.moved(fractionAt(mouse.x));
        }
        onReleased: releaseTimer.restart()
        onCanceled: releaseTimer.restart()
    }

    Timer {
        id: releaseTimer

        interval: 600
        onTriggered: {
            if (!mouse.pressed)
                root.moving = false;
        }
    }

    onValueChanged: {
        if (!mouse.pressed) {
            root.moving = true;
            releaseTimer.restart();
        }
    }
}
