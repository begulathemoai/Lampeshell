import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import qs.theme
import qs.services

Variants {
    id: root
    model: Quickshell.screens

    delegate: PanelWindow {
        id: wallpaperWindow
        required property var modelData
        screen: modelData

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        color: "transparent"
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell-wallpaper"
        WlrLayershell.exclusiveZone: -1

        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

        readonly property real pixelScale: screen && screen.scale ? screen.scale : 1

        readonly property string wallpaperSource: ThemeService.currentWallpaper.length > 0
            ? "file://" + ThemeService.currentWallpaper
            : Theme.wallpaper

        Item {
            id: fadeRoot

            anchors.fill: parent

            opacity: FullscreenState.isFullscreen(wallpaperWindow.monitor) ? 0 : 1

            Behavior on opacity {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }

        Image {
            id: image

            anchors.fill: parent
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            cache: true
            sourceSize: Qt.size(
                Math.ceil(parent.width * wallpaperWindow.pixelScale),
                Math.ceil(parent.height * wallpaperWindow.pixelScale)
            )
            source: wallpaperWindow.wallpaperSource

            opacity: 0

            onStatusChanged: {
                if (status === Image.Ready)
                    fadeIn.restart();
            }

            SequentialAnimation {
                id: fadeIn
                NumberAnimation {
                    target: image
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.background
            visible: image.status === Image.Error || wallpaperWindow.wallpaperSource.length === 0

            Column {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "sentiment_stressed"
                    color: Theme.on_surface_variant
                    opacity: 0.5
                    font {
                        family: "Material Symbols Rounded"
                        pixelSize: 40
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No wallpaper set"
                    color: Theme.on_surface_variant
                    font {
                        family: "Google Sans"
                        pixelSize: 14
                        weight: Font.Medium
                    }
                }
            }
        }
    }
    }
}
