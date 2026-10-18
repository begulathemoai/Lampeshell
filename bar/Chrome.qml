pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.services
import "../theme"

Variants {
    id: root
    model: Quickshell.screens

    delegate: PanelWindow {
        id: chromeWindow

        required property var modelData
        screen: modelData

        color: "transparent"

        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
        visible: !FullscreenState.isFullscreen(monitor)

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell-bezels"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        mask: Region {
            item: chromeShape
            intersection: Intersection.Xor
        }

        Shape {
            id: chromeShape
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(Theme.shadow.r, Theme.shadow.g, Theme.shadow.b, 0.69)
                shadowVerticalOffset: 0
                shadowHorizontalOffset: 0
                blurMax: 20
                shadowBlur: 0.5
            }

            readonly property real sw: chromeWindow.width
            readonly property real sh: chromeWindow.height
            readonly property real corner: Layout.cornerRadius

            readonly property real cutL: Layout.sideBarWidth
            readonly property real cutT: Layout.topBarHeight
            readonly property real cutR: sw - Layout.rightBarWidth
            readonly property real cutB: sh - Layout.bottomBarHeight

            readonly property string outerPath: `M 0,0 L ${sw},0 L ${sw},${sh} L 0,${sh} Z`

            readonly property string cutoutPath: {
                const x0 = cutL, x1 = cutR, y0 = cutT, y1 = cutB;
                const r = corner;
                return `M ${x0},${y0 + r}`
                    + ` L ${x0},${y1 - r}`
                    + ` Q ${x0},${y1} ${x0 + r},${y1}`
                    + ` L ${x1 - r},${y1}`
                    + ` Q ${x1},${y1} ${x1},${y1 - r}`
                    + ` L ${x1},${y0 + r}`
                    + ` Q ${x1},${y0} ${x1 - r},${y0}`
                    + ` L ${x0 + r},${y0}`
                    + ` Q ${x0},${y0} ${x0},${y0 + r} Z`;
            }

            ShapePath {
                fillColor: Theme.surface_container_lowest
                strokeWidth: 0
                strokeColor: "transparent"
                fillRule: ShapePath.WindingFill

                PathSvg {
                    path: `${chromeShape.outerPath} ${chromeShape.cutoutPath}`
                }
            }
        }
    }
}
