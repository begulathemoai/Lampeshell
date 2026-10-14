pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

FileView {
    id: root

    readonly property string colorsPath: Quickshell.env("LAMP_SHELL_COLORS")
        || Quickshell.shellPath("theme/colors.json")
    path: root.colorsPath
    watchChanges: true
    onFileChanged: reload()

    property string wallpaper: "file://" + colors.wallpaper_path

    property alias wallpaperPath: colors.wallpaper_path
    property alias accent: colors.accent
    property alias accentSource: colors.accent_source
    property alias sourceColor: colors.source_color

    property alias primary: colors.primary
    property alias on_primary: colors.on_primary
    property alias primary_container: colors.primary_container
    property alias on_primary_container: colors.on_primary_container
    property alias primary_fixed: colors.primary_fixed
    property alias primary_fixed_dim: colors.primary_fixed_dim
    property alias on_primary_fixed: colors.on_primary_fixed
    property alias on_primary_fixed_variant: colors.on_primary_fixed_variant
    property alias inverse_primary: colors.inverse_primary

    property alias secondary: colors.secondary
    property alias on_secondary: colors.on_secondary
    property alias secondary_container: colors.secondary_container
    property alias on_secondary_container: colors.on_secondary_container
    property alias secondary_fixed: colors.secondary_fixed
    property alias secondary_fixed_dim: colors.secondary_fixed_dim
    property alias on_secondary_fixed: colors.on_secondary_fixed
    property alias on_secondary_fixed_variant: colors.on_secondary_fixed_variant

    property alias tertiary: colors.tertiary
    property alias on_tertiary: colors.on_tertiary
    property alias tertiary_container: colors.tertiary_container
    property alias on_tertiary_container: colors.on_tertiary_container
    property alias tertiary_fixed: colors.tertiary_fixed
    property alias tertiary_fixed_dim: colors.tertiary_fixed_dim
    property alias on_tertiary_fixed: colors.on_tertiary_fixed
    property alias on_tertiary_fixed_variant: colors.on_tertiary_fixed_variant

    property alias error: colors.error
    property alias on_error: colors.on_error
    property alias error_container: colors.error_container
    property alias on_error_container: colors.on_error_container
    property alias critical: colors.error
    property alias on_critical: colors.on_error

    property alias background: colors.background
    property alias on_background: colors.on_background
    property alias surface: colors.surface
    property alias on_surface: colors.on_surface
    property alias surface_dim: colors.surface_dim
    property alias surface_bright: colors.surface_bright
    property alias surface_tint: colors.surface_tint
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

    function on(c: color): color {
        if (c.hslLightness < 0.5)
            return Qt.hsla(c.hslHue, c.hslSaturation, 0.9, 1);
        return Qt.hsla(c.hslHue, c.hslSaturation, 0.1, 1);
    }

    JsonAdapter {
        id: colors

        property string wallpaper_path: ""
        property string accent: ""
        property string accent_source: ""
        property color source_color: "#6750a4"

        property color primary: "#cfbdfe"
        property color on_primary: "#36275d"
        property color primary_container: "#4d3d75"
        property color on_primary_container: "#e9ddff"
        property color primary_fixed: "#e9ddff"
        property color primary_fixed_dim: "#cfbdfe"
        property color on_primary_fixed: "#201047"
        property color on_primary_fixed_variant: "#4d3d75"
        property color inverse_primary: "#65558f"

        property color secondary: "#cbc2db"
        property color on_secondary: "#332d41"
        property color secondary_container: "#4a4458"
        property color on_secondary_container: "#e8def8"
        property color secondary_fixed: "#e8def8"
        property color secondary_fixed_dim: "#cbc2db"
        property color on_secondary_fixed: "#1e192b"
        property color on_secondary_fixed_variant: "#4a4458"

        property color tertiary: "#efb8c8"
        property color on_tertiary: "#4a2532"
        property color tertiary_container: "#633b48"
        property color on_tertiary_container: "#ffd9e3"
        property color tertiary_fixed: "#ffd9e3"
        property color tertiary_fixed_dim: "#efb8c8"
        property color on_tertiary_fixed: "#31101d"
        property color on_tertiary_fixed_variant: "#633b48"

        property color error: "#ffb4ab"
        property color on_error: "#690005"
        property color error_container: "#93000a"
        property color on_error_container: "#ffdad6"

        property color background: "#141218"
        property color on_background: "#e6e0e9"
        property color surface: "#141218"
        property color on_surface: "#e6e0e9"
        property color surface_dim: "#141218"
        property color surface_bright: "#3b383e"
        property color surface_tint: "#cfbdfe"
        property color surface_variant: "#49454e"
        property color on_surface_variant: "#cac4cf"
        property color inverse_surface: "#e6e0e9"
        property color inverse_on_surface: "#322f35"

        property color surface_container_lowest: "#0f0d13"
        property color surface_container_low: "#1d1b20"
        property color surface_container: "#211f24"
        property color surface_container_high: "#2b292f"
        property color surface_container_highest: "#36343a"

        property color outline: "#948f99"
        property color outline_variant: "#49454e"
        property color shadow: "#000000"
        property color scrim: "#000000"
    }
}