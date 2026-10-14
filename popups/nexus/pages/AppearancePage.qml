import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.theme
import qs.services
import qs.popups.settings
import qs.popups.nexus
import qs.popups.nexus.common

PageBase {
    id: root

    title: "Appearance"
    description: "Wallpaper and accent"

    SettingsCard {
        title: "Wallpaper"
        subtitle: ThemeService.hasWallpaper
            ? ThemeService.currentWallpaper.split("/").pop()
            : "No wallpaper applied."

        Column {
            width: parent.width
            spacing: 12

            Rectangle {
                width: parent.width
                height: Math.round(width / 3.2)
                radius: 14
                color: Theme.surface_container_highest
                clip: true
                border.width: 1
                border.color: Theme.outline_variant

                Image {
                    id: currentPreview
                    anchors.fill: parent
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(560, 175)
                    source: ThemeService.hasWallpaper ? "file://" + ThemeService.currentWallpaper : ""
                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 160
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Theme.surface_container_highest
                    visible: currentPreview.status !== Image.Ready

                    Text {
                        anchors.centerIn: parent
                        text: ThemeService.hasWallpaper ? "image" : "hide_image"
                        color: Theme.on_surface_variant
                        opacity: 0.45
                        font {
                            family: "Material Symbols Rounded"
                            pixelSize: 26
                        }
                    }
                }
            }

            Row {
                spacing: 10

                ActionButton {
                    text: ThemeService.busy ? "Generating..." : "Choose wallpaper"
                    icon: "image"
                    primary: true
                    enabled: !ThemeService.busy

                    onTriggered: root.nState.openSubPage(1)
                }

                ActionButton {
                    text: "Re-apply colours"
                    icon: "palette"
                    enabled: ThemeService.hasWallpaper && !ThemeService.busy
                    onTriggered: ThemeService.applyWallpaper(ThemeService.currentWallpaper)
                }

                ActionButton {
                    text: "Revert"
                    icon: "undo"
                    enabled: ThemeService.hasWallpaper
                    onTriggered: ThemeService.revertTheme()
                }
            }

            Text {
                width: parent.width
                visible: ThemeService.lastError.length > 0
                text: ThemeService.lastError
                color: Theme.critical
                wrapMode: Text.WordWrap
                font {
                    family: "Google Sans"
                    pixelSize: 11
                }
            }

            Text {
                width: parent.width
                text: "The accent above is generated from the wallpaper by matugen. Pick one of the fixed accents below to override it."
                color: Theme.on_surface_variant
                wrapMode: Text.WordWrap
                font {
                    family: "Google Sans"
                    pixelSize: 11
                }
            }
        }
    }

    SettingsCard {
        title: "Fixed accents"
        subtitle: "Overrides the generated palette. Only applies while no wallpaper is generating colours."

        Grid {
            id: swatchGrid
            width: parent.width
            columns: 4
            spacing: 12

            Repeater {
                model: root.nState.accentPalette.swatches

                delegate: Item {
                    id: swatchTile
                    required property int index

                    readonly property var swatch: root.nState.accentPalette.swatches[index]
                    readonly property bool isActive: root.nState.accentPalette.activeIndex === index

                    width: (swatchGrid.width - 36) / 4
                    height: 52

                    Rectangle {
                        anchors.fill: parent
                        radius: 14
                        color: swatchTile.swatch.primary
                        opacity: swatchMouse.containsMouse ? 1.0 : 0.85
                        scale: swatchMouse.pressed ? 0.94 : 1.0
                        transformOrigin: Item.Center

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 120
                            }
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + 6
                        height: parent.height + 6
                        radius: 17
                        color: "transparent"
                        border.width: 2
                        border.color: Theme.on_surface
                        visible: swatchTile.isActive
                    }

                    Text {
                        anchors.centerIn: parent
                        text: swatchTile.swatch.name
                        color: swatchTile.swatch.on
                        font {
                            family: "Google Sans"
                            pixelSize: 11
                            weight: Font.Medium
                        }
                    }

                    MouseArea {
                        id: swatchMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.nState.accentPalette.applyAccent(swatchTile.index)
                    }
                }
            }
        }
    }

    SectionHeader {
        text: "How the accent is chosen"
        description: "matugen extracts a source colour from the image (the most saturated of the dominant colours), builds a Material 3 scheme from it in dark mode, and the tokens are written into theme/colors.json. Theme.qml watches that file, so the change applies live without reloading the shell."
    }

    SettingsGroup {
        title: "Overlay effects"
        description: "Applies the shell's own blur and fade to its overlay windows. Turn off to stop the shell touching those layers; your compositor's own rules take over once it reloads."

        ToggleRow {
            icon: "animation"
            label: "Managed by Lampshell"
            checked: SettingsStore.get("overlayEffectsManaged") === true
            onToggled: function(checked) {
                SettingsStore.set("overlayEffectsManaged", checked);
            }
        }
    }
}
