import QtQuick
import qs.services
import qs.theme
import qs.bar.widgets.calendar

Item {
    id: root

    property bool vertical: false

    readonly property int verticalPillWidth: Layout.barThickness - Layout.s(4)

    implicitWidth: visualPill.implicitWidth
    implicitHeight: visualPill.implicitHeight

    Rectangle {
        id: visualPill
        anchors.centerIn: parent

        implicitWidth: root.vertical
            ? root.verticalPillWidth
            : timeLabel.implicitWidth + Layout.s(32)
        implicitHeight: root.vertical
            ? verticalColumn.implicitHeight + Layout.s(14)
            : timeLabel.implicitHeight + Layout.s(16)
        radius: Math.min(width, height) / 2

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
            visible: !root.vertical
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

        Column {
            id: verticalColumn
            anchors.centerIn: parent
            visible: root.vertical
            width: root.verticalPillWidth - Layout.s(10)
            spacing: 0

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: Time.hourText
                color: Theme.on_surface
                font {
                    family: "Google Sans"
                    pointSize: 14
                    weight: Font.Medium
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Layout.s(14)
                height: 1.5
                radius: height / 2
                color: Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.35)
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: Time.minuteText
                color: Theme.on_surface
                font {
                    family: "Google Sans"
                    pointSize: 14
                    weight: Font.Medium
                }
            }

            Text {
                visible: !Time.use24Hour
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: Time.periodText
                color: Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.7)
                font {
                    family: "Google Sans"
                    pointSize: 10
                    weight: Font.Medium
                }
            }

            Item {
                width: 1
                height: Layout.s(3)
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                text: Time.dateSummary
                color: Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.8)
                font {
                    family: "Google Sans"
                    pointSize: 11
                    weight: Font.Medium
                }
            }
        }
    }
}
