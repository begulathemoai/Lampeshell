import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell._Window
import Quickshell.Hyprland
import Quickshell.Io
import qs.theme
import qs.services
import qs.popups.nexus

FloatingWindow {
    id: settingsWindow

    implicitWidth: 980
    implicitHeight: 660
    minimumSize.width: 720
    minimumSize.height: 480
    title: "Shell Settings"
    color: "transparent"
    visible: false

    onClosed: {
        nexusState.overlayOpen = false;
        settingsWindow.visible = false;
    }

    property var targetScreen: Quickshell.screens[0]

    function screenForFocus() {
        const active = Hyprland.focusedMonitor ?? null;
        return active && active.name
            ? Quickshell.screens.find(s => s.name === active.name) ?? Quickshell.screens[0]
            : Quickshell.screens[0];
    }
    screen: targetScreen

    NexusState {
        id: nexusState
        host: settingsWindow

        quickSettingsBackend: quickSettingsBackend
        targetScreen: settingsWindow.targetScreen
    }

    function open() {
        settingsWindow.targetScreen = settingsWindow.screenForFocus();
        settingsWindow.visible = true;
        Qt.callLater(function() { rootSurface.forceActiveFocus(); });
    }

    function close() {
        nexusState.overlayOpen = false;
        settingsWindow.visible = false;
    }

    function toggle() {
        if (settingsWindow.visible)
            close();
        else
            open();
    }

    function goTo(label) {
        const idx = PageRegistry.pages.findIndex(p => p.label === label);
        if (idx >= 0)
            nexusState.currentPageIdx = idx;
        return idx;
    }

    function goToSubPage(sectionLabel, subPageIdx) {
        if (goTo(sectionLabel) < 0)
            return false;
        Qt.callLater(function() {
            nexusState.openSubPage(subPageIdx);
        });
        return true;
    }

    IpcHandler {
        target: "shellSettings"

        function toggle() {
            settingsWindow.toggle();
        }

        function open() {
            settingsWindow.open();
        }

        function close() {
            settingsWindow.close();
        }

        function page(label: string) {
            if (settingsWindow.goTo(label) < 0)
                console.warn("shellSettings: unknown page", label);
            settingsWindow.open();
        }

        function accent(colour: string) {
            AccentPalette.applyCustom(colour);
        }

        function wallpapers() {
            settingsWindow.goToSubPage("Appearance", 1);
            settingsWindow.open();
        }

        function revert() {
            AccentPalette.revert();
        }
    }


    QuickSettingsBackend {
        id: quickSettingsBackend
    }

    Rectangle {
        id: rootSurface
        anchors.fill: parent

        radius: Layout.cornerRadius
        color: Theme.surface_container_low
        border.width: 1
        border.color: Theme.outline_variant
        focus: true

        Keys.onEscapePressed: function(event) {

            if (nexusState.subPageIdxStack.length > 0) {
                nexusState.closeSubPage();
            } else {
                settingsWindow.close();
            }
            event.accepted = true;
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 1.0
            shadowColor: Qt.rgba(Theme.shadow.r, Theme.shadow.g, Theme.shadow.b, 0.50)
            shadowVerticalOffset: 12
        }

        MouseArea {
            anchors.fill: parent
        }

        NavPane {
            id: navPane
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 12
            nState: nexusState
        }

        Rectangle {
            anchors.left: navPane.right
            anchors.leftMargin: 4
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 12
            width: 1
            color: Theme.outline_variant
            opacity: 0.5
        }

        Pages {
            anchors.left: navPane.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: 28
            anchors.rightMargin: 28
            anchors.topMargin: 26
            anchors.bottomMargin: 26
            nState: nexusState
        }

        Rectangle {
            id: closeButton
            visible: !nexusState.overlayOpen
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 18
            width: 32
            height: 32
            radius: 16
            color: closeMouse.containsMouse
                ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.10)
                : "transparent"

            Text {
                anchors.centerIn: parent
                text: "close"
                color: Theme.on_surface_variant
                font {
                    family: "Material Symbols Rounded"
                    pixelSize: 18
                }
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: settingsWindow.close()
            }
        }
    }
}
