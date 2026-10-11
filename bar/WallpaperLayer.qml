import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import qs.theme
import qs.services

/**
 * Draws the wallpaper behind everything.
 *
 * Sits on the Bottom layer, which is above the compositor's own background but
 * below the Top/Overlay layers the bars and bezels use - so the shell's chrome
 * still draws over it and input still reaches client windows, since anything
 * below the normal layer cannot intercept it.
 *
 * Caelestia keeps its wallpaper in a full-screen window inside the same drawer
 * surface as the bar. This is the same idea as a standalone surface: the point
 * is that the wallpaper is never composited by a separate daemon, so it cannot
 * disagree with the theme about which image is current.
 */
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
        WlrLayershell.exclusiveZone: -1 // never reserve space for the wallpaper

        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

        // The surface stays mapped even while something covers the whole
        // output. Toggling `visible` unmapped and remapped it, and the remap
        // landed after the fullscreen transition had already finished - so the
        // wallpaper popped in late every time you left a fullscreen game.
        // Fading an inner item instead keeps the surface (and its decoded
        // image) alive, so leaving fullscreen is a cross-fade.

        // sourceSize keeps the decode at the surface's real pixel size. On a
        // scaled output the surface is larger in device pixels than in layout
        // units, and decoding the full-resolution original for every pixel of
        // every screen is what makes naive wallpaper layers stutter.
        readonly property real pixelScale: screen && screen.scale ? screen.scale : 1

        // ThemeService owns the current wallpaper; Theme.wallpaper reads it back
        // out of colors.json. Preferring the service means the picker and the
        // desktop can never disagree about which image is current.
        readonly property string wallpaperSource: ThemeService.currentWallpaper.length > 0
            ? "file://" + ThemeService.currentWallpaper
            : Theme.wallpaper

        // Fullscreen cross-fade. Entering fades out so the wallpaper is not
        // composited under the game; leaving fades back in over the transition
        // instead of appearing all at once at the end.
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

        // Shown when colors.json points at an image that is not there, which is
        // what a wallpaper_path left over from another machine looks like.
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
