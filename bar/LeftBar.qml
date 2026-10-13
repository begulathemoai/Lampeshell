import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import qs.theme
import qs.services

Variants {
    id: root
    model: Quickshell.screens

    property var launcherHandler: function() {}

    delegate: PanelWindow {
        id: sideBarWindow

        required property var modelData
        screen: modelData

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-leftbar"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
        readonly property bool fullscreen: FullscreenState.isFullscreen(monitor)
        readonly property bool isFocused: Hyprland.focusedMonitor
            && (Hyprland.focusedMonitor.name === modelData.name)

        anchors {
            top: true
            left: true
            bottom: true
        }

        color: "transparent"

        visible: !fullscreen
        implicitWidth: fullscreen ? 0 : Layout.sideBarWidth
        WlrLayershell.exclusiveZone: fullscreen ? 0 : Layout.sideBarWidth

        Behavior on implicitWidth {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Component.onCompleted: {
            if (isFocused)
                Layout.targetMonitor = modelData.name;
        }
        Connections {
            target: Hyprland
            function onFocusedMonitorChanged() {
                if (modelData.name === Hyprland.focusedMonitor.name)
                    Layout.targetMonitor = modelData.name;
            }
        }

        SidebarContent {
            id: sidebar
            anchors {
                fill: parent
                margins: 8
            }
            visible: sideBarWindow.isFocused
            onLauncherRequested: root.launcherHandler()
        }
    }
}
