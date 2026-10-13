import QtQuick
import qs.services
import qs.theme
import qs.bar.widgets.calendar

Item {
    id: root

    implicitWidth: visualPill.implicitWidth
    implicitHeight: visualPill.implicitHeight

    Rectangle {
        id: visualPill
        anchors.centerIn: parent

        implicitWidth: timeLabel.implicitWidth + Layout.s(32)
        implicitHeight: timeLabel.implicitHeight + Layout.s(16)
        radius: height / 2

        color: {
            if (DashboardState.open)

                return Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12));
            if (pillMouse.containsMouse)

                return Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08));

            return Theme.surface_container;
        }

        scale: pillMouse.pressed ? 0.95 : 1.0

        Behavior on color {
            ColorAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            id: pillMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: DashboardState.requestToggle()
        }

        Text {
            id: timeLabel
            anchors.centerIn: parent
            text: Time.time

            color: Theme.on_surface

            font {
                family: "Google Sans"
                pointSize: 14
                weight: Font.Medium
            }

            Behavior on color {
                ColorAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
