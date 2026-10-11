import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import qs.theme
import qs.services

Variants {
    id: root
    model: Quickshell.screens

    delegate: PanelWindow {
        id: sideBarWindow

        // --- Screen Mapping ---
        required property var modelData
        screen: modelData

        // --- Layer Shell Configuration ---
        WlrLayershell.layer: WlrLayer.Overlay
        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
        readonly property bool fullscreen: FullscreenState.isFullscreen(monitor)

        // Collapse rather than destroy: see TopBar.qml for why toggling
        // `visible` breaks the exclusive zone on the way back.

        // --- Geometry & Positioning ---
        anchors {
            top: true
            left: true
            bottom: true
        }

        // --- Visual Styling ---
        color: "transparent"

        implicitWidth: fullscreen ? 0 : Layout.sideBarWidth
        WlrLayershell.exclusiveZone: fullscreen ? 0 : Layout.sideBarWidth

        Behavior on implicitWidth {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
    }
}
