import QtQuick
import qs.theme

Rectangle {
    id: root

    property string label: ""
    property string icon: ""
    property bool active: false

    signal picked()

    implicitHeight: 38
    radius: height / 2

    color: active
        ? Theme.primary_container
        : (chipMouse.containsMouse
            ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)
            : "transparent")

    border.width: active ? 0 : 1
    border.color: Theme.outline_variant

    Behavior on color {
        ColorAnimation {
            duration: 110
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon.length > 0
            text: root.icon
            color: root.active ? Theme.on_primary_container : Theme.on_surface_variant
            font {
                family: "Material Symbols Rounded"
                pixelSize: 17
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root.active ? Theme.on_primary_container : Theme.on_surface
            font {
                family: "Google Sans"
                pixelSize: 13
                weight: root.active ? Font.Medium : Font.Normal
            }
        }
    }

    MouseArea {
        id: chipMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.picked()
    }
}