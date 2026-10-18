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

    anchors {
        top: Layout.barAtTop
        bottom: Layout.barAtBottom
        left: Layout.barAtLeft
        right: Layout.barAtRight
    }
    margins {
        top: Layout.barAtTop ? Layout.topBarHeight : 0
        bottom: Layout.barAtBottom ? Layout.bottomBarHeight : 0
        left: Layout.barAtLeft ? Layout.sideBarWidth : 0
        right: Layout.barAtRight ? Layout.rightBarWidth : 0
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
        topLeftRadius: (Layout.barAtTop || Layout.barAtLeft) ? 0 : 32
        topRightRadius: (Layout.barAtTop || Layout.barAtRight) ? 0 : 32
        bottomLeftRadius: (Layout.barAtBottom || Layout.barAtLeft) ? 0 : 32
        bottomRightRadius: (Layout.barAtBottom || Layout.barAtRight) ? 0 : 32

        border.color: Theme.outline_variant
        border.width: 1

        CalendarGrid {
            anchors.fill: parent

            isWindowVisible: root.visible

            onRequestClose: root.visible = false
        }
    }
}
