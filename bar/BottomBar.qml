import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import qs.theme
import qs.services

/**
 * A transparent shell container positioned at the bottom of every connected screen.
 */
Variants {
    id: root
    model: Quickshell.screens

    delegate: PanelWindow {
        id: bottomBarWindow

        // --- Screen Mapping ---
        required property var modelData
        screen: modelData

        // --- Layer Shell Configuration ---
        WlrLayershell.layer: WlrLayer.Overlay

        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
        readonly property bool fullscreen: FullscreenState.isFullscreen(monitor)

        // Collapse rather than destroy: see TopBar.qml for why toggling

        // --- Geometry & Positioning ---
        anchors {
            left: true
            right: true
            bottom: true
        }

        // --- Visual Styling ---
        color: "transparent"

        implicitHeight: fullscreen ? 0 : Layout.bottomBarHeight
        WlrLayershell.exclusiveZone: fullscreen ? 0 : Layout.bottomBarHeight

        Behavior on implicitHeight {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
    }
}
