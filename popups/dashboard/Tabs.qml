import QtQuick
import qs.theme
import qs.services

Item {
    id: root

    implicitHeight: tabRow.height + Layout.s(5) + indicator.height + separator.height

    readonly property var tabs: [
        { icon: "dashboard", label: "Dashboard" },
        { icon: "queue_music", label: "Media" },
        { icon: "speed", label: "Performance" },
        { icon: "cloud", label: "Weather" }
    ]

    readonly property real tabCell: tabRow.width / tabs.length

    Row {
        id: tabRow

        width: parent.width
        height: Layout.s(52)

        Repeater {
            id: repeater

            model: root.tabs

            Item {
                id: tabItem

                required property int index
                required property var modelData

                readonly property bool current: DashboardState.tab === index
                readonly property real contentWidth: Math.max(iconText.width, labelText.width)

                width: root.tabCell
                height: tabRow.height

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    radius: Layout.s(12)
                    color: tabMouse.containsMouse
                        ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)
                        : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.duration(Motion.fastEffects)
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: Layout.s(2)

                    Text {
                        id: iconText
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tabItem.modelData.icon
                        color: tabItem.current ? Theme.primary : Theme.on_surface_variant
                        font {
                            family: Layout.fontIcons
                            pixelSize: Layout.s(22)
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: Motion.duration(Motion.fastEffects)
                            }
                        }
                    }

                    Text {
                        id: labelText
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tabItem.modelData.label
                        color: tabItem.current ? Theme.primary : Theme.on_surface_variant
                        font {
                            family: Layout.fontSans
                            pixelSize: Layout.s(12)
                            weight: Font.Medium
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: Motion.duration(Motion.fastEffects)
                            }
                        }
                    }
                }

                MouseArea {
                    id: tabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: DashboardState.tab = tabItem.index

                    onWheel: event => {
                        if (event.angleDelta.y < 0)
                            DashboardState.tab = Math.min(DashboardState.tab + 1, root.tabs.length - 1);
                        else if (event.angleDelta.y > 0)
                            DashboardState.tab = Math.max(DashboardState.tab - 1, 0);
                    }
                }
            }
        }
    }

    Item {
        id: indicator

        y: tabRow.height + Layout.s(5)
        implicitHeight: 3
        height: implicitHeight

        readonly property var currentItem: repeater.count > 0 ? repeater.itemAt(DashboardState.tab) : null

        implicitWidth: currentItem ? currentItem.contentWidth : root.tabCell
        width: implicitWidth

        x: root.tabCell * DashboardState.tab + (root.tabCell - width) / 2

        clip: true

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.height * 2
            radius: height / 2
            color: Theme.primary
        }

        Behavior on x {
            NumberAnimation {
                duration: Motion.duration(Motion.fastSpatial)
                easing.type: Easing.OutCubic
            }
        }

        Behavior on implicitWidth {
            NumberAnimation {
                duration: Motion.duration(Motion.fastSpatial)
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        id: separator

        y: indicator.y + indicator.height
        width: parent.width
        height: 1
        color: Theme.outline_variant
    }
}
