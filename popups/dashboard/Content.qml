import QtQuick
import qs.theme
import qs.services

Item {
    id: root

    implicitWidth: Layout.s(1060)
    implicitHeight: Layout.s(560)

    focus: true

    Keys.onEscapePressed: DashboardState.requestClose()

    Tabs {
        id: tabs

        anchors.top: parent.top
        anchors.topMargin: Layout.s(10)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Layout.s(24)
        anchors.rightMargin: Layout.s(24)
    }

    Item {
        id: viewport

        anchors.top: tabs.bottom
        anchors.topMargin: Layout.s(4)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Layout.s(16)
        anchors.rightMargin: Layout.s(16)
        anchors.bottomMargin: Layout.s(12)
        clip: true

        Flickable {
            id: view

            anchors.fill: parent
            contentWidth: row.width
            contentHeight: row.height
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds
            interactive: true

            contentX: DashboardState.tab * viewport.width
            Behavior on contentX {
                NumberAnimation {
                    duration: Motion.duration(Motion.defaultSpatial)
                    easing.type: Easing.OutCubic
                }
            }

            onMovementEnded: {
                const idx = Math.round(contentX / viewport.width);
                DashboardState.tab = Math.max(0, Math.min(3, idx));
                contentX = Qt.binding(() => DashboardState.tab * viewport.width);
            }

            Row {
                id: row
                spacing: 0

                DashboardTab {
                    width: viewport.width
                    height: viewport.height
                }

                MediaTab {
                    width: viewport.width
                    height: viewport.height
                }

                PerformanceTab {
                    width: viewport.width
                    height: viewport.height
                }

                WeatherTab {
                    width: viewport.width
                    height: viewport.height
                }
            }
        }
    }

    onVisibleChanged: if (visible) forceActiveFocus()
}
