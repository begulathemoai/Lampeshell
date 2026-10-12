import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects
import Quickshell.Services.Notifications
import qs.theme
import qs.services

Variants {
    id: root
    model: Quickshell.screens

    delegate: PanelWindow {
        id: notifWindow

        required property var modelData
        screen: modelData

        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
        readonly property bool isFocused: Hyprland.focusedMonitor && modelData.name === Hyprland.focusedMonitor.name
        readonly property var cards: isFocused ? Notifs.popups : []

        Component.onCompleted: {
            if (isFocused)
                Notifs.focusedMonitor = monitor;
        }
        Connections {
            target: Hyprland
            function onFocusedMonitorChanged() {
                if (modelData.name === Hyprland.focusedMonitor.name)
                    Notifs.focusedMonitor = monitor;
            }
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "notification_overlay"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        color: "transparent"

        anchors { top: true; right: true }
        margins { top: 40; right: 5 }

        visible: notifWindow.surfaceActive
        implicitWidth: notifWindow.surfaceActive ? 390 : 0
        implicitHeight: notifWindow.surfaceActive ? modelData.height : 0

        Timer { id: exitTimer; interval: 350 }
        onCardsChanged: { if (cards.length === 0) exitTimer.restart(); }
        readonly property bool surfaceActive: cards.length > 0 || exitTimer.running

        Item {
            id: stack
            width: 350
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 20
            anchors.rightMargin: 20
            visible: notifWindow.isFocused

            Column {
                id: cardColumn
                width: 350
                spacing: 12

                Repeater {
                    model: notifWindow.cards
                    delegate: NotifCard {
                        required property var modelData
                        notif: modelData
                        window: notifWindow
                    }
                }
            }
        }
    }
}
