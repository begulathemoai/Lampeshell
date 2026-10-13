pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

Singleton {
    id: root

    readonly property string colorsPath: Quickshell.shellPath("theme/colors.json")

    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME")
        || (Quickshell.env("HOME") + "/.config")
    readonly property string qtengineDir: configHome + "/qtengine"
    readonly property string schemePath: qtengineDir + "/lampshell.colors"
    readonly property string configPath: qtengineDir + "/qtengine/config.json"

    Timer {
        id: debounce
        interval: 250
        onTriggered: root.writeScheme()
    }

    function sync() {
        debounce.restart();
    }

    Timer {
        id: startupWatch
        interval: 200
        repeat: true
        running: true

        property int attempts: 0

        onTriggered: {
            if (Theme.surface) {
                root.writeScheme();
                startupWatch.stop();
            } else if (startupWatch.attempts++ > 50) {
                console.warn("QtColors: theme never loaded, no scheme written");
                startupWatch.stop();
            }
        }
    }

    function schemeIni() {
        const c = key => (Theme[key] !== undefined ? String(Theme[key]).toLowerCase() : "#000000");
        return [
            "[ColorEffects:Disabled]",
            "Color=" + c("surface"),
            "ColorAmount=0.5",
            "ColorEffect=3",
            "ContrastAmount=0",
            "ContrastEffect=0",
            "IntensityAmount=0",
            "IntensityEffect=0",
            "",
            "[ColorEffects:Inactive]",
            "ChangeSelectionColor=true",
            "Color=#000000",
            "ColorAmount=0.025",
            "ColorEffect=0",
            "ContrastAmount=0.1",
            "ContrastEffect=0",
            "Enable=true",
            "IntensityAmount=0",
            "IntensityEffect=0",
            "",
            "[Colors:Window]",
            "BackgroundAlternate=" + c("surface_container_high"),
            "BackgroundNormal=" + c("surface"),
            "DecorationFocus=" + c("primary"),
            "DecorationHover=" + c("primary"),
            "ForegroundActive=" + c("on_surface_variant"),
            "ForegroundInactive=" + c("outline"),
            "ForegroundLink=" + c("primary"),
            "ForegroundNegative=" + c("critical"),
            "ForegroundNeutral=" + c("surface_bright"),
            "ForegroundNormal=" + c("on_surface"),
            "ForegroundPositive=" + c("tertiary"),
            "ForegroundVisited=" + c("secondary"),
            "",
            "[Colors:View]",
            "BackgroundAlternate=" + c("surface_container_lowest"),
            "BackgroundNormal=" + c("surface_container_low"),
            "DecorationFocus=" + c("primary"),
            "DecorationHover=" + c("primary_container"),
            "ForegroundActive=" + c("on_surface_variant"),
            "ForegroundInactive=" + c("outline"),
            "ForegroundLink=" + c("primary"),
            "ForegroundNegative=" + c("critical"),
            "ForegroundNeutral=" + c("surface_bright"),
            "ForegroundNormal=" + c("on_surface"),
            "ForegroundPositive=" + c("tertiary"),
            "ForegroundVisited=" + c("secondary"),
            "",
            "[Colors:Button]",
            "BackgroundAlternate=" + c("surface_container_highest"),
            "BackgroundNormal=" + c("surface_container_high"),
            "DecorationFocus=" + c("primary"),
            "DecorationHover=" + c("primary_container"),
            "ForegroundActive=" + c("on_surface_variant"),
            "ForegroundInactive=" + c("outline"),
            "ForegroundLink=" + c("primary"),
            "ForegroundNegative=" + c("critical"),
            "ForegroundNormal=" + c("on_surface"),
            "ForegroundPositive=" + c("tertiary"),
            "ForegroundVisited=" + c("secondary"),
            "",
            "[Colors:Header]",
            "BackgroundAlternate=" + c("surface_container_high"),
            "BackgroundNormal=" + c("surface_container_high"),
            "DecorationFocus=" + c("primary"),
            "DecorationHover=" + c("primary_container"),
            "ForegroundActive=" + c("on_surface_variant"),
            "ForegroundInactive=" + c("outline"),
            "ForegroundNormal=" + c("on_surface"),
            "ForegroundPositive=" + c("tertiary"),
            "",
            "[Colors:Tooltip]",
            "BackgroundAlternate=" + c("surface_container_highest"),
            "BackgroundNormal=" + c("surface_container_high"),
            "DecorationFocus=" + c("primary"),
            "DecorationHover=" + c("primary"),
            "ForegroundActive=" + c("on_surface_variant"),
            "ForegroundNormal=" + c("on_surface"),
            "",
            "[Colors:Selection]",
            "BackgroundAlternate=" + c("primary"),
            "BackgroundNormal=" + c("primary"),
            "DecorationFocus=" + c("primary"),
            "DecorationHover=" + c("primary_container"),
            "ForegroundActive=" + c("on_primary"),
            "ForegroundInactive=" + c("on_primary"),
            "ForegroundNormal=" + c("on_primary"),
            "",
            "[General]",
            "ColorScheme=Lampshell",
            "Name=Lampshell",
            "shadeSortColumn=true",
            "",
            "[KDE]",
            "contrast=4",
            "",
            "[WM]",
            "activeBackground=" + c("surface_container_high"),
            "activeForeground=" + c("on_surface"),
            "inactiveBackground=" + c("surface_container"),
            "inactiveForeground=" + c("on_surface_variant"),
            ""
        ].join("\n");
    }

    function writeScheme() {
        if (!Theme.surface)
            return;

        schemeFile.setText(schemeIni());
    }

    FileView {
        id: schemeFile
        path: root.schemePath
        blockLoading: false
        watchChanges: false
        printErrors: false
    }


}