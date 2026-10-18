import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import qs.theme
import qs.services
import qs.popups.dashboard

PanelWindow {
    id: root

    implicitWidth: body.implicitWidth + (Layout.barVertical ? Layout.s(24) : Layout.s(48))
    implicitHeight: body.implicitHeight + (Layout.barHorizontal ? Layout.s(24) : Layout.s(48))
    color: "transparent"
    visible: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lampshell_dashboard"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: -1

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

    function screenForFocus() {
        const active = Hyprland.focusedMonitor ?? null;
        return active && active.name ? Quickshell.screens.find(s => s.name === active.name) ?? Quickshell.screens[0] : Quickshell.screens[0];
    }
    property var targetScreen: screenForFocus()
    screen: targetScreen

    property bool shown: false

    property var closeSidebarHandler: null

    onShownChanged: DashboardState.open = shown

    function open() {
        if (closeSidebarHandler)
            closeSidebarHandler();
        root.targetScreen = root.screenForFocus();
        root.shown = true;
        root.visible = true;
        SystemStats.active = true;
        Weather.reload();
        Qt.callLater(function() {
            focusGrab.active = true;
            body.forceActiveFocus();
        });
    }

    function close() {
        root.shown = false;
        focusGrab.active = false;
        SystemStats.active = false;
        hideWhenDone.restart();
    }

    function toggle() {
        if (root.shown || root.visible)
            close();
        else
            open();
    }

    Timer {
        id: hideWhenDone
        interval: Motion.duration(Motion.defaultSpatial) + 50
        onTriggered: {
            if (!root.shown)
                root.visible = false;
        }
    }

    Connections {
        target: DashboardState

        function onCloseRequested() {
            root.close();
        }

        function onOpenRequested() {
            root.open();
        }

        function onToggleRequested() {
            root.toggle();
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        active: false
        onCleared: {
            if (root.shown)
                root.close();
        }
    }

    IpcHandler {
        target: "dashboard"

        function toggle(): void {
            root.toggle();
        }

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }

        function tab(index: int): void {
            DashboardState.tab = index;
        }
    }

    mask: Region {
        item: surface
    }

    Item {
        id: reveal

        anchors.top: Layout.barAtTop || Layout.barVertical ? parent.top : undefined
        anchors.bottom: Layout.barAtBottom ? parent.bottom : undefined
        anchors.left: Layout.barAtLeft || Layout.barHorizontal ? parent.left : undefined
        anchors.right: Layout.barAtRight ? parent.right : undefined

        width: Layout.barHorizontal ? parent.width : (root.shown ? parent.width : 0)
        height: Layout.barHorizontal ? (root.shown ? parent.height : 0) : parent.height
        clip: true

        Behavior on width {
            NumberAnimation {
                duration: Motion.duration(Motion.defaultSpatial)
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: Motion.duration(Motion.defaultSpatial)
                easing.type: Easing.OutCubic
            }
        }

        PanelSurface {
            id: surface

            anchors.fill: parent
            anchors.topMargin: Layout.barAtTop ? 0 : Layout.s(24)
            anchors.bottomMargin: Layout.barAtBottom ? 0 : Layout.s(24)
            anchors.leftMargin: Layout.barAtLeft ? 0 : Layout.s(24)
            anchors.rightMargin: Layout.barAtRight ? 0 : Layout.s(24)

            Content {
                id: body
            }
        }
    }
}
