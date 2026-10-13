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

        // The card belongs to the screen the panel window is on, which
        // follows the focused monitor. Everywhere else this delegate
        // paints the frame alone, because a card drawn at this screen's
        // own resolution on a screen that has no panel is a slab of
        // surface floating over live desktop.
        readonly property bool hasCard: PanelState.screenName.length === 0
            || PanelState.screenName === modelData.name

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell-bezels"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // The chrome is pure decoration, so every click must fall through to
        // whatever is behind it - apps, the bars, the panel. A `Combine` mask
        // on a full-window item is a full-window input region, which swallows
        // the entire desktop; `Xor` inverts it, and an empty mask makes
        // Quickshell mark the surface WindowTransparentForInput. This is what
        // upstream's BezelsMask.qml did before the chrome was split out.
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
            readonly property real cardH: PanelState.cardHeight
            readonly property real cardX: sw - cardWinW + PanelState.leftInset
                + PanelState.cardOffset
            readonly property real cardY: cutT
            readonly property real fillet: Math.min(PanelState.fillet, cardWinW / 2)

            readonly property real cardW: cutR - cardX

            readonly property real cardR: Layout.panelRadius


            readonly property string outerPath: {
                return `M 0,0 L ${sw},0 L ${sw},${sh} L 0,${sh} Z`;
            }

            readonly property string cutoutPath: {
                const x0 = cutL, x1 = cutR, y0 = cutT, y1 = cutB;
                const r = corner;
                const f = fillet;
                const ch = Math.min(cardH, cutB - cutT - corner - f);
                const cx = cardX;
                const cr = Math.min(cardR, cardW / 2, ch);
                const open = chromeWindow.hasCard && ch > 0.5 && cardW > 1 && cx < x1 - 1;

                let d = `M ${x0 + r},${y0}`
                    + ` L ${x0},${y0 + r}`
                    + ` L ${x0},${y1 - r}`
                    + ` Q ${x0},${y1} ${x0 + r},${y1}`
                    + ` L ${x1 - r},${y1}`
                    + ` Q ${x1},${y1} ${x1},${y1 - r}`;

                if (!open) {
                    return d
                        + ` L ${x1},${y0 + r}`
                        + ` Q ${x1},${y0} ${x1 - r},${y0}`
                        + ` L ${x0 + r},${y0} Z`;
                }

                d += ` L ${x1},${y0 + ch + f}`
                    + ` Q ${x1},${y0 + ch} ${x1 - f},${y0 + ch}`
                    + ` L ${cx + cr},${y0 + ch}`
                    + ` Q ${cx},${y0 + ch} ${cx},${y0 + ch - cr}`
                    + ` L ${cx},${y0 + f}`;

                return d
                    + ` Q ${cx},${y0} ${cx - f},${y0}`
                    + ` L ${x0 + r},${y0} Z`;
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