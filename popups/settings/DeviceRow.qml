import QtQuick
import qs.theme

/**
 * One Bluetooth device row.
 *
 * Mirrors Caelestia's popout row: name, optional battery, a connect/disconnect
 * toggle, and a forget button for bonded devices. `paired` switches the row
 * between "known device" (connect / forget) and "available device" (pair).
 */
Item {
    id: root

    // The Quickshell BluetoothDevice. Typed loosely because the page passes
    // values straight out of `adapter.devices`.
    property var device: null
    property bool busy: false

    readonly property string displayName: root.device
        ? (root.device.name || root.device.deviceName || root.device.address || "Unknown device")
        : "Unknown device"
    readonly property bool connected: root.device?.connected === true
    readonly property bool known: !!(root.device && (root.device.bonded || root.device.paired))

    signal action()
    signal forgotten()

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

    implicitHeight: 60
    width: parent ? parent.width : 0

    Row {
        id: row
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        // Status dot: filled when connected, hollow when not.
        Rectangle {
            id: dot
            anchors.verticalCenter: parent.verticalCenter
            width: 10
            height: 10
            radius: 5
            color: root.connected ? Theme.primary : "transparent"
            border.width: root.connected ? 0 : 1.5
            border.color: Theme.outline

            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: row.width - dot.width - batteryIcon.width - connectBtn.width - forgetBtn.width - 48
            spacing: 2

            Text {
                width: parent.width
                text: root.displayName
                color: Theme.on_surface
                elide: Text.ElideRight
                font {
                    family: "Google Sans"
                    pixelSize: 13
                    weight: Font.Medium
                }
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: {
                    if (!root.device)
                        return "";
                    if (root.connected)
                        return root.device.batteryAvailable
                            ? "Connected · " + Math.round(root.device.battery * 100) + "%"
                            : "Connected";
                    return root.known ? "Paired" : "Available";
                }
                color: Theme.on_surface_variant
                elide: Text.ElideRight
                font {
                    family: "Google Sans"
                    pixelSize: 11
                }
            }
        }

        Text {
            id: batteryIcon
            anchors.verticalCenter: parent.verticalCenter
            visible: root.device?.batteryAvailable === true && !root.connected
            text: root.device && root.device.battery < 0.2 ? "battery_alert" : "battery_full"
            color: root.device && root.device.battery < 0.2 ? Theme.critical : Theme.on_surface_variant
            font {
                family: "Material Symbols Rounded"
                pixelSize: 16
            }
        }

        // Connect / disconnect. For an unpaired device this pairs instead,
        Rectangle {
            id: connectBtn
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            height: 34
            radius: 17
            color: {
                if (root.busy)
                    return Theme.surface_container_highest;
                const active = root.known ? root.connected : false;
                return hover.hovered
                    ? Qt.alpha(Theme.primary, active ? 0.32 : 0.18)
                    : (active ? Theme.primary : Theme.surface_container_highest);
            }

            Behavior on color {
                ColorAnimation { duration: 120 }
            }

            Text {
                anchors.centerIn: parent
                text: root.busy ? "progress_activity" : (root.connected ? "link_off" : (root.known ? "link" : "bluetooth_searching"))
                color: root.connected && !root.busy ? Theme.on_primary : Theme.on_surface_variant
                font {
                    family: "Material Symbols Rounded"
                    pixelSize: 18
                }

                RotationAnimator on rotation {
                    running: root.busy
                    loops: Animation.Infinite
                    from: 0; to: 360; duration: 1100
                }
            }

            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }

            // One tap does the sensible thing: toggle a known device, pair an
            TapHandler {
                enabled: !root.busy && root.device !== null
                onTapped: root.action()
            }
        }

        // Forget, only for devices already paired.
        Rectangle {
            id: forgetBtn
            anchors.verticalCenter: parent.verticalCenter
            visible: root.known
            width: 34
            height: 34
            radius: 17
            color: forgetHover.hovered ? Qt.alpha(Theme.critical, 0.18) : "transparent"

            Text {
                anchors.centerIn: parent
                text: "delete"
                color: forgetHover.hovered ? Theme.critical : Theme.on_surface_variant
                font {
                    family: "Material Symbols Rounded"
                    pixelSize: 18
                }
            }

            HoverHandler { id: forgetHover; cursorShape: Qt.PointingHandCursor }

            TapHandler {
                onTapped: root.forgotten()
            }
        }
    }

    // Hairline between rows, matching the card dividers used elsewhere.
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Theme.outline_variant
        visible: root.busy || root.connected
        opacity: 0.5
    }
}