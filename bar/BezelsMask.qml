pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import QtQuick
import QtQuick.Effects
import "../theme"

Variants {
    id: root
    model: Quickshell.screens

    delegate: PanelWindow {
        id: bezelWindow

        required property var modelData
        screen: modelData

        color: "transparent"

        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
        visible: !FullscreenState.isFullscreen(monitor)

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell-bezels"
        WlrLayershell.exclusiveZone: -1

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        mask: Region {
            item: effectContainer
            intersection: Intersection.Xor
        }

        Item {
            id: effectContainer
            anchors.fill: parent

            Item {
                id: bezelLayer
                anchors.fill: parent
                layer.enabled: true

                readonly property real frameRadius: Layout.cornerRadius
                    + (PanelState.merged ? Layout.s(10) : 0)

                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(Theme.shadow.r, Theme.shadow.g, Theme.shadow.b, 0.69)
                    shadowVerticalOffset: 0
                    shadowHorizontalOffset: 0
                    blurMax: 20
                    shadowBlur: 0.5
                }

                Rectangle {
                    id: bezelBackground
                    anchors.fill: parent
                    color: PanelState.merged ? Theme.surface_container_low : Theme.surface_container_lowest
                    layer.enabled: true

                    Behavior on color {
                        ColorAnimation {
                            duration: 280
                            easing.type: Easing.OutCubic
                        }
                    }

                    layer.effect: MultiEffect {
                        maskSource: cutoutShape
                        maskEnabled: true
                        maskInverted: true
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1
                    }
                }

                Item {
                    id: cutoutShape
                    anchors.fill: parent
                    layer.enabled: true
                    visible: false

                    Rectangle {
                        id: clippingRect
                        anchors.fill: parent

                        anchors {
                            leftMargin: Layout.sideBarWidth
                            rightMargin: Layout.rightBarWidth
                            topMargin: Layout.topBarHeight
                            bottomMargin: Layout.bottomBarHeight
                        }

                        radius: bezelLayer.frameRadius

                        Behavior on radius {
                            NumberAnimation {
                                duration: 320
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }
        }
    }
}
