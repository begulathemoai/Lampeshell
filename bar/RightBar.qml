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
        id: rightBarWindow

        required property var modelData
        screen: modelData

        readonly property bool active: Layout.barPosition === "right"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-rightbar"

        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
        readonly property bool fullscreen: FullscreenState.isFullscreen(monitor)

        anchors {
            top: true
            right: true
            bottom: true
        }

        color: "transparent"

        implicitWidth: fullscreen ? 0 : Layout.rightBarWidth
        WlrLayershell.exclusiveZone: fullscreen ? 0 : Layout.rightBarWidth

        Behavior on implicitWidth {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Loader {
            anchors.fill: parent
            active: rightBarWindow.active
            visible: !rightBarWindow.fullscreen

            sourceComponent: Component {
                VerticalBarContent {
                    windowHandle: rightBarWindow
                    statusPillHandler: root.statusPillHandler
                }
            }
        }
    }
}
