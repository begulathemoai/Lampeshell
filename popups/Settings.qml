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

/**
 * Shell settings - a real toplevel window, modelled on Caelestia's "nexus".
 *
 * The interface itself lives in popups/nexus: a nav pane grouped by category, a
 * page host that instantiates one section at a time, and a per-section page stack
 * so a detail view can be pushed and popped. This file is only the window
 * surface, the shared services and the IPC entry points.
 *
 * Uses Quickshell._Window.FloatingWindow, so this is a compositor-managed
 * xdg_toplevel: it floats, can be moved and resized, and appears in
 * hyprctl clients like any other window. The interface exposes no x/y, so
 * placement comes from the windowrule in hyprland/rules.lua.
 *
 * The window is destroyed when hidden rather than kept around: a hidden
 * toplevel still costs a surface, and there is nothing to preserve in state.
 */
FloatingWindow {
    id: settingsWindow

    implicitWidth: 980
    implicitHeight: 660
    minimumSize.width: 720
    minimumSize.height: 480
    title: "Shell Settings"
    color: "transparent"
    visible: false

    onClosed: settingsWindow.visible = false

    // A live binding makes the window follow focus, so focusing it moves it to
    // whichever monitor the focus came from - it would jump between outputs.
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
        accentPalette: accentPalette
        quickSettingsBackend: quickSettingsBackend
        targetScreen: settingsWindow.targetScreen
    }

    function open() {
        settingsWindow.targetScreen = settingsWindow.screenForFocus();
        settingsWindow.visible = true;
        settingsWindow.grabFocus();
        Qt.callLater(function() { rootSurface.forceActiveFocus(); });
    }

    function close() {
        settingsWindow.visible = false;
    }

    function toggle() {
        if (settingsWindow.visible)
            close();
        else
            open();
    }

    // Jump straight to a section by registry index. The IPC surface takes a
    // label instead, because indices shift whenever a section is added.
    function goTo(label) {
        const idx = PageRegistry.pages.findIndex(p => p.label === label);
        if (idx >= 0)
            nexusState.currentPageIdx = idx;
        return idx;
    }

    /**
     * Opens a sub-page inside a section.
     *
     * The push has to be deferred: changing currentPageIdx clears the sub-page
     * stack, and the section's StackPage may not have been constructed yet when
     * the change happens. StackPage replays subPageIdxStack in its
     * Component.onCompleted, so pushing after the clear is enough - the page
     * picks the request up whenever it finishes loading.
     */
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

        // shellSettings page network
        function page(label: string) {
            if (settingsWindow.goTo(label) < 0)
                console.warn("shellSettings: unknown page", label);
            settingsWindow.open();
        }

        function accent(name: string) {
            accentPalette.applyAccent(name);
        }

        // Opens Settings straight to the wallpaper grid. Sub-page 1 of the
        // Appearance section.
        function wallpapers() {
            settingsWindow.goToSubPage("Appearance", 1);
            settingsWindow.open();
        }

        function revert() {
            accentPalette.revert();
        }
    }

    // Shared services. QuickSettingsBackend is instantiated here as well as in
    // the two panels stay in agreement.
    AccentPalette {
        id: accentPalette
    }

    QuickSettingsBackend {
        id: quickSettingsBackend
    }

    // --- Window surface ------------------------------------------------------
    Rectangle {
        id: rootSurface
        anchors.fill: parent
        // Matches Layout.cornerRadius, which is what the screen bezel and the
        // hardcoded 28, so the corners sat visibly rounder than the border the
        radius: Layout.cornerRadius
        color: Theme.surface_container_low
        border.width: 1
        border.color: Theme.outline_variant
        focus: true

        Keys.onEscapePressed: function(event) {
            // A pushed detail view goes back before the window closes.
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

        // Swallow clicks so they do not reach the window behind.
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
