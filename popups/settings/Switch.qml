import QtQuick
import qs.theme

Item {
    id: root

    property bool checked: false
    property bool enabled: true

    signal toggled(bool checked)

    implicitWidth: 52
    implicitHeight: 32

    opacity: enabled ? 1.0 : 0.38

    Behavior on opacity {
        NumberAnimation {
            duration: 120
        }
    }

    Rectangle {
        id: track

        anchors.fill: parent
        radius: height / 2

        color: root.checked ? Theme.primary : Theme.surface_variant

        Behavior on color {
            ColorAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        id: thumb

        readonly property int pad: 2
        readonly property bool squeezed: pressArea.pressed

        width: squeezed ? height * 1.2 : height
        height: root.height - pad * 2
        radius: height / 2
        x: root.checked ? root.width - width - pad : pad
        y: pad

        color: root.checked ? Theme.on_primary : Theme.outline

        Text {
            anchors.centerIn: parent
            text: root.checked ? "check" : "close"
            color: root.checked ? Theme.primary : Theme.on_surface_variant
            font {
                family: "Material Symbols Rounded"
                pixelSize: 16
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.checked ? Theme.primary : Theme.on_surface
            opacity: pressArea.pressed ? 0.1 : pressArea.containsMouse ? 0.08 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                }
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutBack
            }
        }
        Behavior on x {
            NumberAnimation {
                duration: 260
                easing.type: Easing.OutBack
            }
        }
        Behavior on color {
            ColorAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        id: pressArea
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.toggled(!root.checked)
    }
}
