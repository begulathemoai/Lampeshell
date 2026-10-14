import QtQuick
import QtQuick.Controls
import qs.theme

ScrollBar {
    id: control

    implicitWidth: 12
    implicitHeight: 12

    contentItem: Rectangle {

        implicitWidth: 6
        implicitHeight: 6

        radius: width / 2

        color: Theme.primary

        opacity: (control.active || control.hovered || control.pressed) ? 0.9 : 0.32

        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
    }

    background: Rectangle {
        color: "transparent"
    }
}