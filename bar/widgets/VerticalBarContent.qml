import Quickshell
import QtQuick
import "../modules"
import qs.theme
import qs.services

Item {
    id: root
    property var statusPillHandler: function() {}
    required property var windowHandle

    readonly property var screen: windowHandle ? windowHandle.screen : null

    Workspaces {
        id: workspaceModule
        targetMonitor: root.screen ? root.screen.name : ""
        vertical: true
        anchors.top: parent.top
        anchors.topMargin: Layout.s(6)
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Calendar {
        id: calendarModule
        vertical: true
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Column {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Layout.s(6)
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Layout.s(8)

        SystemTray {
            id: statusModule
            windowHandle: root.windowHandle
            vertical: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        CommandCenter {
            id: commandCenterModule
            vertical: true
            onClicked: root.statusPillHandler()
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
