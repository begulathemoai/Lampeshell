import QtQuick
import qs.theme

/**
 * Pill button used for page actions. `primary` picks the filled variant.
 */
Rectangle {
    id: root

    property string text: ""
    property string icon: ""
    property bool primary: false
    // Real signal, not `property var onTriggered`. With a var property,
    // `onTriggered: doSomething()` is a *binding*, so QML ran it once at
    // construction - which launched blueman-manager and opened the wallpaper
    // picker on every shell start. As a signal it only fires when emitted.
    signal triggered()

    implicitWidth: label.implicitWidth + (iconText.visible ? iconText.implicitWidth + 8 : 0) + 34
    implicitHeight: 38
    radius: height / 2

    color: {
        if (primary)
            return mouse.containsMouse ? Qt.lighter(Theme.primary_container, 1.08) : Theme.primary_container;
        return mouse.containsMouse
            ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.10)
            : Theme.surface_container_highest;
    }

    Behavior on color {
        ColorAnimation {
            duration: 110
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 8

        Text {
            id: iconText
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon !== ""
            text: root.icon
            color: root.primary ? Theme.on_primary_container : Theme.on_surface
            font {
                family: "Material Symbols Rounded"
                pixelSize: 17
            }
        }

        Text {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.primary ? Theme.on_primary_container : Theme.on_surface
            font {
                family: "Google Sans"
                pixelSize: 13
                weight: Font.Medium
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }
}