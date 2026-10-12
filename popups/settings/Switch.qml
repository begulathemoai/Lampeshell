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
        border.width: 2
        border.color: root.checked ? Theme.primary : Theme.outline

        Behavior on color {
            ColorAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        id: thumb

        width: root.checked ? 24 : 16
        height: width
        radius: width / 2
        x: root.checked ? 24 : 4
        y: (root.height - height) / 2

        color: root.checked ? Theme.on_primary : Theme.outline

        Text {
            anchors.centerIn: parent
            text: root.checked ? "check" : "close"
            color: root.checked ? Theme.primary : Theme.on_surface_variant
            font {
                family: "Material Symbols Rounded"
                pixelSize: root.checked ? 16 : 12
            }
            opacity: 0
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
        Behavior on height {
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
        Behavior on y {
            NumberAnimation {
                duration: 220
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
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.toggled(!root.checked)
    }
}
