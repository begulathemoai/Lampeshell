import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "modules"
import qs.theme
import qs.services

Variants {
    id: root
    model: Quickshell.screens

    // Set by shell.qml. QML ids do not cross file boundaries, so the status
    // pill cannot reach QuickSettings directly - it calls this.
    // Deliberately not named on* : QML would treat the shell.qml assignment as
    // a signal handler and build a binding loop.
    property var statusPillHandler: function() {}

    delegate: PanelWindow {
        id: mainBar
        required property var modelData
        screen: modelData

        // --- Layer Shell Configuration ---
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-topbar"

        // --- Fullscreen Detection Logic ---
        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
        readonly property bool fullscreen: FullscreenState.isFullscreen(monitor)

        // --- Geometry & Positioning ---
        anchors {
            top: true
            left: true
            right: true
        }
        color: "transparent"

        // exclusive zone drive its layout) makes Hyprland re-lay the bar out, and
        // whole output regardless of exclusive zones, so holding the reservation
        // is harmless and keeps the surface valid.
        implicitHeight: Layout.topBarHeight
        WlrLayershell.exclusiveZone: Layout.topBarHeight

        // Hidden by unmapping the window rather than by fading or resizing a
        // bar come back blank after a fullscreen cycle.
        visible: !mainBar.fullscreen

        // The modules are permanent children anchored to the window's
        // attached across every transition. Nothing is clip: a clipped item
        Workspaces {
            id: workspaceModule
            targetMonitor: mainBar.modelData.name
            anchors {
                left: parent.left
                leftMargin: 15
                verticalCenter: parent.verticalCenter
            }
        }

        Calendar {
            id: calendarModule
            anchors.centerIn: parent
        }

        SystemTray {
            id: statusModule
            windowHandle: mainBar
            anchors {
                right: commandCenterModule.left
                rightMargin: 15
                verticalCenter: parent.verticalCenter
            }
        }

        CommandCenter {
            id: commandCenterModule
            onClicked: root.statusPillHandler()
            anchors {
                right: parent.right
                rightMargin: 15
                verticalCenter: parent.verticalCenter
            }
        }
    }
}