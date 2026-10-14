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
    property real sampleX: 0.5
    property real sampleY: 0.5

    readonly property real cardAspect: ImageSampler.imageWidth > 0 && ImageSampler.imageHeight > 0
        ? ImageSampler.imageWidth / ImageSampler.imageHeight
        : 16 / 9

    function loadSampler() {
        if (ThemeService.hasWallpaper)
            ImageSampler.load("file://" + ThemeService.currentWallpaper);
    }

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

    Component.onCompleted: {
        syncFromSource();
        root.loadSampler();
    }

    Connections {
        target: AccentPalette
        function onCurrentAccentSourceChanged() {
            root.syncFromSource();
        }
    }

    Connections {
        target: ThemeService
        function onCurrentWallpaperChanged() {
            root.loadSampler();
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
            description: "Use the source colour as the accent"
            checked: ThemeService.fidelity
            onToggled: function(checked) {
                ThemeService.fidelity = checked;
                ThemeService.regenerate(root.personalised ? root.currentSource : "");
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
        anchors.fill: parent

        ChoiceDialog {
            id: styleDialog
            anchors.fill: parent
            title: "Theme Style"
            model: ThemeService.styles
            current: ThemeService.effectiveStyleKey
            onChosen: function(key) {
                if (key === ThemeService.styleKey && !ThemeService.fidelity)
                    return;
                ThemeService.fidelity = false;
                ThemeService.styleKey = key;
                ThemeService.regenerate(root.personalised ? root.currentSource : "");
            }
        }

        Rectangle {
            id: wallpaperPicker
            anchors.fill: parent
            visible: root.pickingFromWallpaper
            color: Qt.rgba(0, 0, 0, 0.8)

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.pendingHex = "";
                    root.pickingFromWallpaper = false;
                }
            }

            Rectangle {
                id: pickerCard
                anchors.centerIn: parent
                readonly property real innerWidth: width - 24
                readonly property real imageHeight: Math.max(1, innerWidth / root.cardAspect)
                width: Math.min(parent.width - 64, 780)
                height: Math.min(parent.height - 40, 56 + imageHeight + 96)
                radius: 26
                color: Theme.surface_container
                border.width: 1
                border.color: Theme.outline_variant
                clip: true

                Item {
                    id: pickerHeader
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 56

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Pick from Wallpaper"
                        color: Theme.on_surface
                        font {
                            family: "Google Sans"
                            pixelSize: 16
                            weight: Font.Medium
                        }
                    }

                    MouseArea {
                        id: closeArea
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 38
                        height: 38
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.pendingHex = "";
                            root.pickingFromWallpaper = false;
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "close"
                            color: closeArea.containsMouse ? Theme.on_surface : Theme.on_surface_variant
                            font {
                                family: "Material Symbols Rounded"
                                pixelSize: 20
                            }
                        }
                    }
                }

                Image {
                    id: wallImage
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: pickerHeader.bottom
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    height: pickerCard.imageHeight
                    clip: true
                    source: ThemeService.hasWallpaper ? "file://" + ThemeService.currentWallpaper : ""
                    asynchronous: true
                    fillMode: Image.PreserveAspectFit

                    Rectangle {
                        id: sampleMark
                        visible: wallImage.status === Image.Ready && root.pendingHex.length > 0
                        width: 30
                        height: 30
                        radius: 15
                        color: "transparent"
                        border.width: 3
                        border.color: Theme.on_surface
                        x: root.sampleX * Math.max(0, wallImage.paintedWidth - width)
                        y: root.sampleY * Math.max(0, wallImage.paintedHeight - height)
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
                            root.sampleX = fx;
                            root.sampleY = fy;
                            root.pendingHex = hex;
                            const c = Qt.color(hex);
                            root.hue = c.hsvHue < 0 ? root.hue : c.hsvHue * 360;
                            root.saturation = c.hsvSaturation;
                            root.lightness = c.hsvValue;
                        }
                    }
                }

                Item {
                    id: pickerFooter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: wallImage.bottom
                    height: 96

                    Rectangle {
                        id: pickedChip
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        width: 42
                        height: 42
                        radius: 13
                        color: root.pendingHex.length > 0 ? root.pendingHex : Theme.surface_container_highest
                        border.width: 2
                        border.color: Theme.on_surface
                    }

                    Text {
                        anchors.left: pickedChip.right
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.pendingHex.length > 0 ? root.pendingHex : "Pick a point"
                        color: root.pendingHex.length > 0 ? Theme.on_surface : Theme.on_surface_variant
                        font {
                            family: "Google Sans"
                            pixelSize: 14
                            weight: Font.Medium
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        ActionButton {
                            text: "Cancel"
                            onTriggered: {
                                root.pendingHex = "";
                                root.pickingFromWallpaper = false;
                            }
                        }

                        ActionButton {
                            text: "Apply"
                            primary: true
                            enabled: root.pendingHex.length > 0
                            onTriggered: {
                                AccentPalette.applyCustom(root.pendingHex);
                                root.pendingHex = "";
                                root.pickingFromWallpaper = false;
                            }
                        }
                    }
                }
            }
        }
    }
}