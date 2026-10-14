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

    function activateSearchResult(entry) {
        const idx = PageRegistry.pages.findIndex(p => p.label === entry.page);
        if (idx < 0)
            return;
        nexusState.currentPageIdx = idx;
        if (entry.subPage !== undefined && entry.subPage >= 0) {
            Qt.callLater(function() {
                nexusState.openSubPage(entry.subPage);
            });
        } else {
            Qt.callLater(function() {
                pages.revealSetting(entry.title);
            });
        }
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

        radius: 16
        color: Theme.surface
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
            nState: nexusState
            onResultActivated: entry => settingsWindow.activateSearchResult(entry)
        }

        Item {
            id: titleRow
            anchors.left: navPane.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 12
            height: Layout.s(80)

            Rectangle {
                id: backButton
                visible: nexusState.subPageIdxStack.length > 0
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                height: 36
                radius: 18
                color: backMouse.containsMouse
                    ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.10)
                    : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: 110
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "arrow_back"
                    color: Theme.on_surface_variant
                    font {
                        family: Layout.fontIcons
                        pixelSize: 20
                    }
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: nexusState.closeSubPage()
                }
            }

            Text {
                id: titleText
                anchors.left: backButton.visible ? backButton.right : parent.left
                anchors.leftMargin: backButton.visible ? 8 : 32
                anchors.right: closeButton.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: pages.currentTitle
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
                color: Theme.on_surface
                font {
                    family: Layout.fontSans
                    pixelSize: Layout.s(26)
                    weight: Font.DemiBold
                }

                ParallelAnimation {
                    id: titleAnim

                    NumberAnimation {
                        target: titleText
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 200
                        easing.type: Easing.OutCubic
                    }

                    NumberAnimation {
                        target: titleText
                        property: "scale"
                        from: 0.9
                        to: 1
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }

                onTextChanged: titleAnim.restart()
            }

            Rectangle {
                id: closeButton
                visible: !nexusState.overlayOpen
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 40
                height: 40
                radius: 20
                color: closeMouse.containsMouse
                    ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.10)
                    : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: 110
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "close"
                    color: Theme.on_surface_variant
                    font {
                        family: Layout.fontIcons
                        pixelSize: 20
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

        Rectangle {
            id: contentContainer
            anchors.left: navPane.right
            anchors.right: parent.right
            anchors.top: titleRow.bottom
            anchors.bottom: parent.bottom
            anchors.leftMargin: 0
            anchors.rightMargin: 12
            anchors.bottomMargin: 12
            radius: Layout.panelRadius
            color: Theme.surface_container_low
        }

        Pages {
            id: pages
            anchors.left: contentContainer.left
            anchors.right: contentContainer.right
            anchors.top: contentContainer.top
            anchors.bottom: contentContainer.bottom
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 28
            anchors.bottomMargin: 28
            nState: nexusState
        }
    }
}
