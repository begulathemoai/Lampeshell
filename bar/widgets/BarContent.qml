import Quickshell
import QtQuick
import "../modules"
import qs.theme
import qs.services

Item {
    id: root
    property var statusPillHandler: function() {}
    property var windowHandle
    property bool showMpris: false

    readonly property var screen: windowHandle ? windowHandle.screen : null

    DistroLogo {
        id: logoModule
        anchors {
            left: parent.left
            leftMargin: Layout.s(15)
            verticalCenter: parent.verticalCenter
        }
    }

    Workspaces {
        id: workspaceModule
        targetMonitor: root.screen ? root.screen.name : ""
        anchors {
            left: logoModule.right
            leftMargin: Layout.s(8)
            verticalCenter: parent.verticalCenter
        }
    }

    Calendar {
        id: calendarModule
        anchors.centerIn: parent
    }

    Mpris {
        id: mprisModule
        visible: root.showMpris && SettingsStore.values.musicPlayerWidgetEnabled
        anchors {
            left: calendarModule.right
            right: statusModule.left
            verticalCenter: parent.verticalCenter
        }
    }

    SystemTray {
        id: statusModule
        windowHandle: root.windowHandle
        anchors {
            right: commandCenterModule.left
            rightMargin: Layout.s(15)
            verticalCenter: parent.verticalCenter
        }
    }

    CommandCenter {
        id: commandCenterModule
        onClicked: root.statusPillHandler()
        anchors {
            right: parent.right
            rightMargin: Layout.s(15)
            verticalCenter: parent.verticalCenter
        }
    }
}
