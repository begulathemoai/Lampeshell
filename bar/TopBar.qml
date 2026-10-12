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

    property var statusPillHandler: function() {}

    delegate: PanelWindow {
        id: mainBar
        required property var modelData
        screen: modelData

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

        visible: !mainBar.fullscreen

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
