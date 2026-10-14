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

    property real hue: 205
    property real saturation: 0.65
    property real lightness: 0.55

    readonly property color customColor: Qt.hsva(hue / 360, saturation, lightness, 1)

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
                text: "The accent above is generated from the wallpaper by matugen. Picking an accent below overrides it until you re-apply a wallpaper."
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
        title: "Accent"
        subtitle: AccentPalette.isCustom
            ? "Custom " + AccentPalette.currentAccentSource
            : (AccentPalette.ready
                ? "Fixed accent: " + AccentPalette.currentAccent
                : "No accent palettes found.")

        Column {
            width: parent.width
            spacing: 12

            Grid {
                id: swatchGrid
                width: parent.width
                columns: 4
                spacing: 12

                Repeater {
                    model: AccentPalette.swatches

                    delegate: Item {
                        id: swatchTile
                        required property int index

                        readonly property var swatch: AccentPalette.swatches[index]
                        readonly property bool isActive: AccentPalette.activeIndex === index

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
                            enabled: !ThemeService.busy
                            onClicked: AccentPalette.applyAccent(swatchTile.index)
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.outline_variant
                opacity: 0.4
            }

            Row {
                id: accentInfoRow
                width: parent.width
                spacing: 12

                Rectangle {
                    width: 44
                    height: 44
                    radius: 14
                    color: AccentPalette.isCustom ? AccentPalette.currentAccentSource : Theme.primary_container
                    border.width: AccentPalette.isCustom ? 2 : 1
                    border.color: AccentPalette.isCustom ? Theme.on_surface : "transparent"

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + 6
                        height: parent.height + 6
                        radius: 17
                        color: "transparent"
                        border.width: 2
                        border.color: Theme.on_surface
                        visible: AccentPalette.isCustom
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(0, accentInfoRow.width - 56 - accentRevert.width)
                    text: AccentPalette.isCustom
                        ? "Custom " + AccentPalette.currentAccentSource
                        : "No custom colour set. Use the picker below."
                    color: Theme.on_surface_variant
                    elide: Text.ElideRight
                    font {
                        family: "Google Sans"
                        pixelSize: 11
                    }
                }

                ActionButton {
                    id: accentRevert
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Revert"
                    icon: "undo"
                    enabled: !ThemeService.busy && (AccentPalette.isCustom || AccentPalette.activeIndex >= 0)
                    onTriggered: AccentPalette.revert()
                }
            }
        }
    }

    SettingsCard {
        title: "Custom colour"
        subtitle: "matugen builds a full palette from any colour you pick here, the same way it does for a wallpaper."

        Column {
            width: parent.width
            spacing: 8

            Rectangle {
                width: parent.width
                height: 56
                radius: 14
                color: root.customColor
                border.width: 1
                border.color: Theme.outline

                Text {
                    anchors.centerIn: parent
                    text: root.customColor
                    color: Theme.on(root.customColor)
                    font {
                        family: "Google Sans"
                        pixelSize: 14
                        weight: Font.Medium
                    }
                }
            }

            SliderRow {
                icon: "palette"
                label: "Hue"
                from: 0
                to: 360
                suffix: "\u00b0"
                value: root.hue
                onMoved: function(v) {
                    root.hue = v;
                }
            }

            SliderRow {
                icon: "gradient"
                label: "Saturation"
                from: 0
                to: 100
                value: root.saturation * 100
                onMoved: function(v) {
                    root.saturation = v / 100;
                }
            }

            SliderRow {
                icon: "light_mode"
                label: "Lightness"
                from: 25
                to: 80
                value: root.lightness * 100
                onMoved: function(v) {
                    root.lightness = v / 100;
                }
            }

            ActionButton {
                width: parent.width
                text: ThemeService.busy ? "Generating..." : "Apply custom colour"
                icon: "check"
                primary: true
                enabled: !ThemeService.busy
                onTriggered: AccentPalette.applyCustom(root.customColor)
            }
        }
    }

    SectionHeader {
        text: "How the accent is chosen"
        description: "A wallpaper and a custom colour are treated the same way: matugen extracts a source colour and builds a complete Material 3 scheme from it in dark mode, and the result is written to theme/colors.json. Theme.qml watches that file, so every change applies live without reloading the shell. The fixed accents are the same palettes, pre-generated by scripts/generate-accents so switching to one is instant. Terminal colours are derived from whichever palette is active."
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
