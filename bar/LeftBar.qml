import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "widgets"
import qs.theme
import qs.services

Variants {
    id: root
    model: Quickshell.screens

    property var statusPillHandler: function() {}

    delegate: PanelWindow {
        id: leftBarWindow

        required property var modelData
        screen: modelData

        readonly property bool active: Layout.barPosition === "left"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-leftbar"

        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
        readonly property bool fullscreen: FullscreenState.isFullscreen(monitor)

        anchors {
            top: true
            left: true
            bottom: true
        }

        color: "transparent"

        implicitWidth: fullscreen ? 0 : Layout.sideBarWidth
        WlrLayershell.exclusiveZone: fullscreen ? 0 : Layout.sideBarWidth

        Behavior on implicitWidth {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Loader {
            anchors.fill: parent
            active: leftBarWindow.active
            visible: !leftBarWindow.fullscreen

            sourceComponent: Component {
                VerticalBarContent {
                    windowHandle: leftBarWindow
                    statusPillHandler: root.statusPillHandler
                }
            }
        }
    }
}
