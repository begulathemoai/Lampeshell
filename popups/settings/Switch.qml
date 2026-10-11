import QtQuick
import qs.theme

/**
 * Material 3 Expressive switch, matching Metrolist's ExpressiveSwitch.
 *
 * Track is 52x32 with a 2dp border. The thumb grows from 16dp to 24dp as it
 * travels, which is the expressive part - a plain M3 switch keeps the thumb the
 * same size. The thumb also carries an icon: a check when on, a close when off.
 *
 * Colours follow ExpressiveSwitch rather than stock M3: on-primary thumb on a
 * primary track when checked, outline thumb on a surface-variant track when not.
 */
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

    // --- Track ---
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

    // --- Thumb ---
    Rectangle {
        id: thumb

        // Unchecked: 16dp sitting 4dp in. Checked: 24dp sitting 4dp from the
        width: root.checked ? 24 : 16
        height: width
        radius: width / 2
        x: root.checked ? 24 : 4
        y: (root.height - height) / 2

        color: root.checked ? Theme.on_primary : Theme.outline

        // The icon sits inside the thumb; the smallest thumb is 16dp, so the
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
