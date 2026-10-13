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

            readonly property real cardWinW: PanelState.panelWidth
            readonly property real cardH: PanelState.panelHeight
            readonly property real cardX: sw - cardWinW + PanelState.leftInset
            readonly property real cardY: cutT
            readonly property real fillet: Math.min(PanelState.fillet, cardWinW / 2)

            readonly property real cardW: cutR - cardX

            readonly property real cardR: Layout.cornerRadius


            readonly property string outerPath: {
                const r = corner;
                return `M ${r},0 L ${sw - r},0 Q ${sw},0 ${sw},${r}`
                    + ` L ${sw},${sh - r} Q ${sw},${sh} ${sw - r},${sh}`
                    + ` L ${r},${sh} Q 0,${sh} 0,${sh - r}`
                    + ` L 0,${r} Q 0,0 ${r},0 Z`;
            }

            readonly property string cutoutPath: {
                const x0 = cutL, x1 = cutR, y0 = cutT, y1 = cutB;
                const r = corner;
                return `M ${x0 + r},${y0} L ${x1 - r},${y0} Q ${x1},${y0} ${x1},${y0 + r}`
                    + ` L ${x1},${y1 - r} Q ${x1},${y1} ${x1 - r},${y1}`
                    + ` L ${x0 + r},${y1} Q ${x0},${y1} ${x0},${y1 - r}`
                    + ` L ${x0},${y0 + r} Q ${x0},${y0} ${x0 + r},${y0} Z`;
            }

            readonly property string cardPath: {
                if (cardH <= 0.5 || cardW <= 0)
                    return "";
                const x = cardX;
                const y = cardY;
                const w = cardW;
                const h = cardH;
                const r = Math.min(cardR, w / 2, h);
                const f = fillet;
                return `M ${x + f},${y}`
                    + ` L ${x + w},${y}`
                    + ` L ${x + w},${y + h - r}`
                    + ` Q ${x + w},${y + h} ${x + w - r},${y + h}`
                    + ` L ${x + r},${y + h}`
                    + ` Q ${x},${y + h} ${x},${y + h - r}`
                    + ` L ${x},${y + f}`
                    + ` Q ${x},${y} ${x + f},${y}`
                    + ` Z`;
            }

            ShapePath {
                fillColor: Theme.surface_container_lowest
                strokeWidth: 0
                strokeColor: "transparent"

                fillRule: ShapePath.OddEvenFill

                PathSvg {
                    path: `${chromeShape.outerPath} ${chromeShape.cutoutPath} ${chromeShape.cardPath}`
                }
            }
        }
    }
}