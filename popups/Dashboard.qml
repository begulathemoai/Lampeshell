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

    implicitWidth: Layout.s(1060)
    implicitHeight: Layout.s(560)
    color: "transparent"
    visible: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lampshell_dashboard"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: -1

    anchors.top: true
    margins.top: Layout.topBarHeight

    function screenForFocus() {
        const active = Hyprland.focusedMonitor ?? null;
        return active && active.name ? Quickshell.screens.find(s => s.name === active.name) ?? Quickshell.screens[0] : Quickshell.screens[0];
    }
    property var targetScreen: screenForFocus()
    screen: targetScreen

    function publishGeometry() {
        DashboardState.screenName = root.screen ? root.screen.name : "";
        DashboardState.setContentSize(root.width, root.height);
    }

    onWidthChanged: publishGeometry()
    onTargetScreenChanged: publishGeometry()

    property bool shown: false

    property var closeSidebarHandler: null

    onShownChanged: DashboardState.open = shown

    function open() {
        if (closeSidebarHandler)
            closeSidebarHandler();
        root.targetScreen = root.screenForFocus();
        root.shown = true;
        publishGeometry();
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

    Item {
        id: reveal

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: DashboardState.revealHeight
        clip: true

        Content {
            id: body

            width: root.implicitWidth
            height: DashboardState.cardHeight
            anchors.top: parent.top
        }
    }
}
