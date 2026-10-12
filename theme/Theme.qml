pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

FileView {
    id: root
    path: Quickshell.shellPath("theme/colors.json")
    watchChanges: true
    onFileChanged: reload()

    property string wallpaper: "file://" + colors.wallpaper_path

    property alias wallpaperPath: colors.wallpaper_path

    property alias primary: colors.primary
    property alias on_primary: colors.on_primary
    property alias primary_container: colors.primary_container
    property alias on_primary_container: colors.on_primary_container

    property alias secondary: colors.secondary
    property alias on_secondary: colors.on_secondary
    property alias secondary_container: colors.secondary_container
    property alias on_secondary_container: colors.on_secondary_container

    property alias tertiary: colors.tertiary
    property alias on_tertiary: colors.on_tertiary
    property alias tertiary_container: colors.tertiary_container
    property alias on_tertiary_container: colors.on_tertiary_container

    property alias background: colors.background
    property alias on_background: colors.on_background
    property alias surface: colors.surface
    property alias on_surface: colors.on_surface

    property alias surface_dim: colors.surface_dim
    property alias surface_bright: colors.surface_bright

    property alias surface_variant: colors.surface_variant
    property alias on_surface_variant: colors.on_surface_variant
    property alias inverse_surface: colors.inverse_surface
    property alias inverse_on_surface: colors.inverse_on_surface

    property alias surface_container_lowest: colors.surface_container_lowest
    property alias surface_container_low: colors.surface_container_low
    property alias surface_container: colors.surface_container
    property alias surface_container_high: colors.surface_container_high
    property alias surface_container_highest: colors.surface_container_highest

    property alias outline: colors.outline
    property alias outline_variant: colors.outline_variant
    property alias shadow: colors.shadow
    property alias scrim: colors.scrim

    property alias critical: colors.critical
    property alias on_critical: colors.on_critical

    JsonAdapter {
        id: colors

        property string wallpaper_path: ""
        property color primary: "#6750a4"
        property color on_primary: "#ffffff"
        property color primary_container: "#eaddff"
        property color on_primary_container: "#21005d"

        property color secondary: "#625b71"
        property color on_secondary: "#ffffff"
        property color secondary_container: "#e8def8"
        property color on_secondary_container: "#1d192b"

        property color tertiary: "#7d5260"
        property color on_tertiary: "#ffffff"
        property color tertiary_container: "#ffd8e4"
        property color on_tertiary_container: "#31111d"

        property color background: "#1c1b1f"
        property color on_background: "#e6e1e5"
        property color surface: "#1c1b1f"
        property color on_surface: "#e6e1e5"
        property color surface_dim: "#141218"
        property color surface_bright: "#413738"

        property color surface_variant: "#49454f"
        property color on_surface_variant: "#cac4d0"
        property color inverse_surface: "#e6e1e5"
        property color inverse_on_surface: "#313033"

        property color surface_container_lowest: "#0f0d13"
        property color surface_container_low: "#1d1b20"
        property color surface_container: "#211f26"
        property color surface_container_high: "#2b2930"
        property color surface_container_highest: "#36343b"

        property color outline: "#938f99"
        property color outline_variant: "#49454f"
        property color shadow: "#000000"
        property color scrim: "#000000"

        property color critical: "#b3261e"
        property color on_critical: "#ffffff"
    }
}
