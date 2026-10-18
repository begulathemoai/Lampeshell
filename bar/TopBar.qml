import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "modules"
import "widgets"
import qs.theme
import qs.services

Variants {
    id: root
    model: Quickshell.screens

    property var statusPillHandler: function() {}

    delegate: PanelWindow {
        id: mainBar
        required property var modelData
        screen: modelData

        readonly property bool active: Layout.barPosition === "top"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-topbar"

        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
        readonly property bool fullscreen: FullscreenState.isFullscreen(monitor)

        anchors {
            top: true
            left: true
            right: true
        }
        color: "transparent"

        implicitHeight: Layout.topBarHeight
        WlrLayershell.exclusiveZone: Layout.topBarHeight

        visible: !fullscreen

        Loader {
            anchors.fill: parent
            active: mainBar.active
            visible: !mainBar.fullscreen

            sourceComponent: Component {
                BarContent {
                    windowHandle: mainBar
                    statusPillHandler: root.statusPillHandler
                    showMpris: true
                }
            }
        }
    }
}
