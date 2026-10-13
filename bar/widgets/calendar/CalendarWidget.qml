import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.theme

PanelWindow {
    id: root

    implicitWidth: Layout.s(700)
    implicitHeight: Layout.s(480)
    color: "transparent"

    anchors.top: true
    margins {
        top: Layout.topBarHeight + Layout.s(20)
        right: Layout.s(16)
    }

    WlrLayershell.namespace: "calendar_widget"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        active: root.visible
        onCleared: root.visible = false
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.surface_container_lowest
        radius: 32

        border.color: Theme.outline_variant
        border.width: 1

        CalendarGrid {
            anchors.fill: parent

            isWindowVisible: root.visible

            onRequestClose: root.visible = false
        }
    }
}
