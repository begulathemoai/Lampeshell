import QtQuick
import QtQuick.Layouts
import Quickshell
import Lampshell.Services
import qs.theme
import qs.services
import qs.popups.settings
import qs.popups.nexus
import qs.popups.nexus.common

PageBase {
    id: root

    title: "Appearance"
    description: "Customize your palette"

    property real hue: 205
    property real saturation: 0.65
    property real lightness: 0.55

    property bool personalised: AccentPalette.isCustom

    property bool pickingFromWallpaper: false
    property string pendingHex: ""

    readonly property color customColor: Qt.hsva(hue / 360, saturation, lightness, 1)

    readonly property string currentSource: AccentPalette.isCustom
        ? AccentPalette.currentAccentSource
        : ""

    readonly property color previewColor: AccentPalette.isCustom && currentSource.length > 0
        ? currentSource
        : Theme.primary

    function setHue(value) {
        hue = Math.max(0, Math.min(359, value));
    }

    function syncFromSource() {
        if (!AccentPalette.isCustom || currentSource.length !== 7)
            return;
        const c = Qt.color(currentSource);
        hue = c.hsvHue < 0 ? root.hue : c.hsvHue * 360;
        saturation = c.hsvSaturation;
        lightness = c.hsvValue;
    }

    function applyCustomColor(hex) {
        if (typeof hex === "string" && hex.length === 7)
            pendingHex = hex;
        pendingHex = "";
        AccentPalette.applyCustom(root.customColor);
    }

    Component.onCompleted: syncFromSource()

    Connections {
        target: AccentPalette
        function onCurrentAccentSourceChanged() {
            root.syncFromSource();
        }
    }

    SettingsCard {
        title: "Theme Colors"
        subtitle: root.personalised ? "Using custom color" : "Following wallpaper"

        Item {
            width: parent.width
            height: Math.max(bodyCol.implicitHeight, 64)

            Rectangle {
                id: previewChip
                anchors.right: parent.right
                width: 44
                height: 44
                radius: 14
                color: root.previewColor

                border.width: root.personalised ? 2 : 0
                border.color: Theme.on_surface
            }

            Column {
                id: bodyCol
                anchors.left: parent.left
                anchors.right: previewChip.left
                anchors.rightMargin: 14
                anchors.top: parent.top
                spacing: 10

                Row {
                    width: parent.width
                    spacing: 10

                    SegmentedChoice {
                        width: (parent.width - 10) / 2
                        label: "Automatic"
                        icon: "auto_awesome"
                        active: !root.personalised
                        onPicked: {
                            root.personalised = false;
                            ThemeService.applyWallpaper(ThemeService.currentWallpaper);
                        }
                    }

                    SegmentedChoice {
                        width: (parent.width - 10) / 2
                        label: "Personnalisé"
                        icon: "palette"
                        active: root.personalised
                        onPicked: root.personalised = true
                    }
                }

                Column {
                    width: parent.width
                    spacing: 10
                    visible: root.personalised

                    Text {
                        width: parent.width
                        text: "Choose how to pick your custom color:"
                        color: Theme.on_surface_variant
                        font {
                            family: "Google Sans"
                            pixelSize: 11
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 10

                        ActionButton {
                            width: (parent.width - 10) / 2
                            text: "From Wallpaper"
                            icon: "colorize"
                            enabled: ThemeService.hasWallpaper && !ThemeService.busy
                            onTriggered: root.pickingFromWallpaper = true
                        }

                        ActionButton {
                            width: (parent.width - 10) / 2
                            text: "Color Picker"
                            icon: "palette"
                            enabled: !ThemeService.busy
                            onTriggered: root.personalised = true
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 62
                        radius: 16
                        color: Theme.surface_container_highest

                        Rectangle {
                            id: chip
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: 38
                            height: 38
                            radius: 12
                            color: root.customColor
                        }

                        Column {
                            anchors.left: chip.right
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                text: "Selected Color"
                                color: Theme.on_surface_variant
                                font {
                                    family: "Google Sans"
                                    pixelSize: 11
                                }
                            }

                            Text {
                                text: root.customColor
                                color: Theme.on_surface
                                font {
                                    family: "Google Sans"
                                    pixelSize: 12
                                    weight: Font.Medium
                                }
                            }
                        }

                        ActionButton {
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: ThemeService.busy ? "..." : "Apply"
                            primary: true
                            enabled: !ThemeService.busy
                            onTriggered: AccentPalette.applyCustom(root.customColor)
                        }
                    }

                    SliderRow {
                        icon: "palette"
                        label: "Hue"
                        from: 0
                        to: 359
                        suffix: "°"
                        value: root.hue
                        onMoved: function(v) {
                            root.setHue(v);
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
                        label: "Brightness"
                        from: 25
                        to: 80
                        value: root.lightness * 100
                        onMoved: function(v) {
                            root.lightness = v / 100;
                        }
                    }
                }
            }
        }
    }

    SettingsGroup {
        title: "Theme Style"

        SettingsRow {
            icon: "palette"
            label: "Theme Style"
            description: ThemeService.styleLabel
            onClicked: root.styleDialog.open = true

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "chevron_right"
                color: Theme.on_surface_variant
                font {
                    family: "Material Symbols Rounded"
                    pixelSize: 20
                }
            }
        }
    }

    SettingsGroup {
        title: "Fine Tuning"

        ToggleRow {
            icon: "tune"
            label: "Fidelity"
            description: "Keep the source colour's hue and saturation"
            checked: ThemeService.fidelity
            onToggled: function(checked) {
                ThemeService.fidelity = checked;
            }
        }

        SliderRow {
            icon: "contrast"
            label: "Contrast Level"
            enabled: !ThemeService.fidelity
            value: (ThemeService.contrast + 1) * 50
            valueLabel: ThemeService.fidelity ? "Fidelity" : ThemeService.contrastLabel
            onMoved: function(v) {
                ThemeService.contrast = (v - 50) / 50;
            }
        }

        SliderRow {
            icon: "tonality"
            label: "Chroma Boost"
            enabled: !ThemeService.fidelity
            value: ThemeService.chromaPercent
            onMoved: function(v) {
                ThemeService.chromaBoost = v / 100;
            }
        }
    }

    Rectangle {
        width: parent.width
        height: infoCol.implicitHeight + 32
        radius: 20
        color: Theme.surface_container

        Column {
            id: infoCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 4

            Text {
                width: parent.width
                text: "About Color Customization"
                color: Theme.on_surface
                font {
                    family: "Google Sans"
                    pixelSize: 13
                    weight: Font.Medium
                }
            }

            Text {
                width: parent.width
                text: "Colour changes apply across the shell and to any app that reads the generated theme file. Adjusting these may change how other apps look."
                color: Theme.on_surface_variant
                wrapMode: Text.WordWrap
                font {
                    family: "Google Sans"
                    pixelSize: 11
                }
            }
        }
    }

    overlay: Item {
        ChoiceDialog {
            id: styleDialog
            width: parent.width
            height: parent.height
            title: "Theme Style"
            model: ThemeService.styles
            current: ThemeService.styleKey
            onChosen: function(key) {
                ThemeService.styleKey = key;
                ThemeService.regenerate(root.personalised ? root.currentSource : "");
            }
        }

        Rectangle {
            id: wallpaperPicker
            anchors.fill: parent
            visible: root.pickingFromWallpaper
            color: Qt.rgba(0, 0, 0, 0.72)

            Image {
                id: wallImage
                anchors.fill: parent
                anchors.margins: 28
                source: ThemeService.hasWallpaper ? "file://" + ThemeService.currentWallpaper : ""
                asynchronous: true
                fillMode: Image.PreserveAspectFit

                Rectangle {
                    id: sampleMark
                    visible: wallImage.status === Image.Ready && root.pendingHex.length > 0
                    width: 34
                    height: 34
                    radius: 17
                    color: "transparent"
                    border.width: 3
                    border.color: Theme.on_surface
                    x: (wallImage.paintedWidth - width) / 2
                    y: (wallImage.paintedHeight - height) / 2
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: wallImage.status === Image.Ready
                    cursorShape: Qt.CrossCursor
                    onClicked: function(mouse) {
                        const w = wallImage.paintedWidth;
                        const h = wallImage.paintedHeight;
                        const fx = (mouse.x - (wallImage.width - w) / 2) / Math.max(1, w);
                        const fy = (mouse.y - (wallImage.height - h) / 2) / Math.max(1, h);
                        if (fx < 0 || fx > 1 || fy < 0 || fy > 1)
                            return;
                        const hex = ImageSampler.sampleAtFraction(fx, fy);
                        if (hex.length !== 7)
                            return;
                        root.pendingHex = hex;
                        const c = Qt.color(hex);
                        root.hue = c.hsvHue < 0 ? root.hue : c.hsvHue * 360;
                        root.saturation = c.hsvSaturation;
                        root.lightness = c.hsvValue;
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: "Pick from Wallpaper"
                color: Theme.on_surface
                font {
                    family: "Google Sans"
                    pixelSize: 20
                    weight: Font.Medium
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 40
                visible: root.pendingHex.length > 0
                text: "Selected Color:  " + root.pendingHex
                color: Theme.on_surface
                font {
                    family: "Google Sans"
                    pixelSize: 14
                }
            }

            ActionButton {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 36
                text: "Cancel"
                onTriggered: {
                    root.pendingHex = "";
                    root.pickingFromWallpaper = false;
                }
            }

            ActionButton {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 36
                visible: root.pendingHex.length > 0
                text: "Apply"
                primary: true
                onTriggered: {
                    AccentPalette.applyCustom(root.pendingHex);
                    root.pendingHex = "";
                    root.pickingFromWallpaper = false;
                }
            }
        }
    }
}