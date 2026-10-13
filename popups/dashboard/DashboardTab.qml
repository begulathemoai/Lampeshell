import QtQuick
import qs.theme
import qs.services
import qs.bar.widgets.calendar

// The Dashboard tab: clock + calendar on the left, a resource column in the
// middle and the now-playing media card on the right (as in caelestia's Dash).
Item {
    id: root

    implicitWidth: Layout.s(1028)
    implicitHeight: Layout.s(470)

    readonly property color cpuColor: Theme.primary
    readonly property color memColor: Theme.tertiary
    readonly property color diskColor: Theme.secondary

    Row {
        anchors.centerIn: parent
        spacing: Layout.s(20)

        CalendarGrid {
            id: calendar

            width: Layout.s(700)
            height: Layout.s(440)
            anchors.verticalCenter: parent.verticalCenter

            isWindowVisible: DashboardState.open

            onRequestClose: DashboardState.requestClose()
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Layout.s(22)

            Repeater {
                model: [
                    { icon: "memory", label: "CPU", frac: SystemStats.cpu / 100, value: Math.round(SystemStats.cpu) + "%", color: root.cpuColor },
                    { icon: "memory_alt", label: "RAM", frac: SystemStats.memFraction, value: Math.round(SystemStats.memFraction * 100) + "%", color: root.memColor },
                    { icon: "hard_drive", label: "Disk", frac: SystemStats.diskFraction, value: Math.round(SystemStats.diskFraction * 100) + "%", color: root.diskColor }
                ]

                Column {
                    required property var modelData

                    spacing: Layout.s(6)

                    ProgressRing {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Layout.s(74)
                        height: Layout.s(74)
                        value: modelData.frac
                        fgColor: modelData.color
                        strokeWidth: Layout.s(6)

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            color: modelData.color
                            font {
                                family: Layout.fontIcons
                                pixelSize: Layout.s(24)
                            }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
                        color: Theme.on_surface_variant
                        font {
                            family: Layout.fontSans
                            pixelSize: Layout.s(12)
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.value
                        color: Theme.on_surface
                        font {
                            family: Layout.fontSans
                            pixelSize: Layout.s(13)
                            weight: Font.Medium
                        }
                    }
                }
            }
        }

        MediaCard {
            width: Layout.s(200)
            height: Layout.s(440)
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
