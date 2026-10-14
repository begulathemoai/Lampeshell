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

        readonly property bool hasCard: PanelState.screenName.length === 0
            || PanelState.screenName === modelData.name

        readonly property bool hasDashCard: DashboardState.screenName.length === 0
            || DashboardState.screenName === modelData.name

        readonly property bool hasLaunchCard: LauncherState.screenName.length === 0
            || LauncherState.screenName === modelData.name

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
            readonly property real cardH: PanelState.cardHeight
            readonly property real cardX: sw - cardWinW + PanelState.leftInset
                + PanelState.cardOffset
            readonly property real cardY: cutT
            readonly property real fillet: Math.min(PanelState.fillet, cardWinW / 2)

            readonly property real cardW: cutR - cardX

            readonly property real cardR: Layout.panelRadius

            readonly property real dashW: DashboardState.panelWidth
            readonly property real dashH: DashboardState.revealHeight
            readonly property real dashX: (sw - dashW) / 2
            readonly property real dashRight: dashX + dashW
            readonly property real dashFillet: Math.min(corner, dashW / 4)

            readonly property real launchW: LauncherState.panelWidth
            readonly property real launchH: LauncherState.revealHeight
            readonly property real launchX: (sw - launchW) / 2
            readonly property real launchRight: launchX + launchW
            readonly property real launchFillet: Math.min(corner, launchW / 4)


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

                const dch = Math.min(dashH, cutB - cutT - corner - dashFillet);
                const dcr = Math.min(Layout.panelRadius, dashW / 2, dch);
                const dopen = chromeWindow.hasDashCard && dch > 0.5 && dashW > 1
                    && dashX > x0 + r && dashRight < x1 - r;

                const lch = Math.min(launchH, cutB - cutT - corner - launchFillet);
                const lcr = Math.min(Layout.panelRadius, launchW / 2, lch);
                const lopen = chromeWindow.hasLaunchCard && lch > 0.5 && launchW > 1
                    && launchX > x0 + r && launchRight < x1 - r;

                let d = `M ${x0},${y0 + r}`
                    + ` L ${x0},${y1 - r}`
                    + ` Q ${x0},${y1} ${x0 + r},${y1}`;

                if (lopen) {
                    d += ` L ${launchX - launchFillet},${y1}`
                        + ` Q ${launchX},${y1} ${launchX},${y1 - launchFillet}`
                        + ` L ${launchX},${y1 - lch + lcr}`
                        + ` Q ${launchX},${y1 - lch} ${launchX + lcr},${y1 - lch}`
                        + ` L ${launchRight - lcr},${y1 - lch}`
                        + ` Q ${launchRight},${y1 - lch} ${launchRight},${y1 - lch + lcr}`
                        + ` L ${launchRight},${y1 - launchFillet}`
                        + ` Q ${launchRight},${y1} ${launchRight + launchFillet},${y1}`
                        + ` L ${x1 - r},${y1}`;
                } else {
                    d += ` L ${x1 - r},${y1}`;
                }

                d += ` Q ${x1},${y1} ${x1},${y1 - r}`;

                let cursor;

                if (open) {
                    d += ` L ${x1},${y0 + ch + f}`
                        + ` Q ${x1},${y0 + ch} ${x1 - f},${y0 + ch}`
                        + ` L ${cx + cr},${y0 + ch}`
                        + ` Q ${cx},${y0 + ch} ${cx},${y0 + ch - cr}`
                        + ` L ${cx},${y0 + f}`
                        + ` Q ${cx},${y0} ${cx - f},${y0}`;
                    cursor = cx - f;
                } else {
                    d += ` L ${x1},${y0 + r}`
                        + ` Q ${x1},${y0} ${x1 - r},${y0}`;
                    cursor = x1 - r;
                }

                if (dopen && dashRight < cursor - 1) {
                    d += ` L ${dashRight + dashFillet},${y0}`
                        + ` Q ${dashRight},${y0} ${dashRight},${y0 + dashFillet}`
                        + ` L ${dashRight},${y0 + dch - dcr}`
                        + ` Q ${dashRight},${y0 + dch} ${dashRight - dcr},${y0 + dch}`
                        + ` L ${dashX + dcr},${y0 + dch}`
                        + ` Q ${dashX},${y0 + dch} ${dashX},${y0 + dch - dcr}`
                        + ` L ${dashX},${y0 + dashFillet}`
                        + ` Q ${dashX},${y0} ${dashX - dashFillet},${y0}`;
                    cursor = dashX - dashFillet;
                }

                return d
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