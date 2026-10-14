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

    property color primary: root.tuned(colors.primary, "primary")
    property color on_primary: root.tuned(colors.on_primary, "on_primary")
    property color primary_container: root.tuned(colors.primary_container, "primary_container")
    property color on_primary_container: root.tuned(colors.on_primary_container, "on_primary_container")
    property color primary_fixed: root.tuned(colors.primary_fixed, "primary_fixed")
    property color primary_fixed_dim: root.tuned(colors.primary_fixed_dim, "primary_fixed_dim")
    property color on_primary_fixed: root.tuned(colors.on_primary_fixed, "on_primary_fixed")
    property color on_primary_fixed_variant: root.tuned(colors.on_primary_fixed_variant, "on_primary_fixed_variant")
    property color inverse_primary: root.tuned(colors.inverse_primary, "inverse_primary")

    property color secondary: root.tuned(colors.secondary, "secondary")
    property color on_secondary: root.tuned(colors.on_secondary, "on_secondary")
    property color secondary_container: root.tuned(colors.secondary_container, "secondary_container")
    property color on_secondary_container: root.tuned(colors.on_secondary_container, "on_secondary_container")
    property color secondary_fixed: root.tuned(colors.secondary_fixed, "secondary_fixed")
    property color secondary_fixed_dim: root.tuned(colors.secondary_fixed_dim, "secondary_fixed_dim")
    property color on_secondary_fixed: root.tuned(colors.on_secondary_fixed, "on_secondary_fixed")
    property color on_secondary_fixed_variant: root.tuned(colors.on_secondary_fixed_variant, "on_secondary_fixed_variant")

    property color tertiary: root.tuned(colors.tertiary, "tertiary")
    property color on_tertiary: root.tuned(colors.on_tertiary, "on_tertiary")
    property color tertiary_container: root.tuned(colors.tertiary_container, "tertiary_container")
    property color on_tertiary_container: root.tuned(colors.on_tertiary_container, "on_tertiary_container")
    property color tertiary_fixed: root.tuned(colors.tertiary_fixed, "tertiary_fixed")
    property color tertiary_fixed_dim: root.tuned(colors.tertiary_fixed_dim, "tertiary_fixed_dim")
    property color on_tertiary_fixed: root.tuned(colors.on_tertiary_fixed, "on_tertiary_fixed")
    property color on_tertiary_fixed_variant: root.tuned(colors.on_tertiary_fixed_variant, "on_tertiary_fixed_variant")

    property color error: root.tuned(colors.error, "error")
    property color on_error: root.tuned(colors.on_error, "on_error")
    property color error_container: root.tuned(colors.error_container, "error_container")
    property color on_error_container: root.tuned(colors.on_error_container, "on_error_container")
    property color critical: root.tuned(colors.error, "error")
    property color on_critical: root.tuned(colors.on_error, "on_error")

    property color background: root.tuned(colors.background, "background")
    property color on_background: root.tuned(colors.on_background, "on_background")
    property color surface: root.tuned(colors.surface, "surface")
    property color on_surface: root.tuned(colors.on_surface, "on_surface")
    property color surface_dim: root.tuned(colors.surface_dim, "surface_dim")
    property color surface_bright: root.tuned(colors.surface_bright, "surface_bright")
    property color surface_tint: root.tuned(colors.surface_tint, "surface_tint")
    property color surface_variant: root.tuned(colors.surface_variant, "surface_variant")
    property color on_surface_variant: root.tuned(colors.on_surface_variant, "on_surface_variant")
    property color inverse_surface: root.tuned(colors.inverse_surface, "inverse_surface")
    property color inverse_on_surface: root.tuned(colors.inverse_on_surface, "inverse_on_surface")

    property color surface_container_lowest: root.tuned(colors.surface_container_lowest, "surface_container_lowest")
    property color surface_container_low: root.tuned(colors.surface_container_low, "surface_container_low")
    property color surface_container: root.tuned(colors.surface_container, "surface_container")
    property color surface_container_high: root.tuned(colors.surface_container_high, "surface_container_high")
    property color surface_container_highest: root.tuned(colors.surface_container_highest, "surface_container_highest")

    property color outline: root.tuned(colors.outline, "outline")
    property color outline_variant: root.tuned(colors.outline_variant, "outline_variant")
    property color shadow: root.tuned(colors.shadow, "shadow")
    property color scrim: root.tuned(colors.scrim, "scrim")

    function on(c: color): color {
        if (c.hslLightness < 0.5)
            return Qt.hsla(c.hslHue, c.hslSaturation, 0.9, 1);
        return Qt.hsla(c.hslHue, c.hslSaturation, 0.1, 1);
    }

    property real contrast: 0
    property real chromaBoost: 0
    property bool fidelity: false

    readonly property var accentRoles: [
        "primary", "primary_container", "primary_fixed", "primary_fixed_dim",
        "secondary", "secondary_container", "secondary_fixed", "secondary_fixed_dim",
        "tertiary", "tertiary_container", "tertiary_fixed", "tertiary_fixed_dim",
        "surface_tint"
    ]

    function toColor(hex) {
        if (hex === undefined || hex === null)
            return null;
        if (typeof hex !== "string")
            return hex;
        const s = hex.charAt(0) === "#" ? hex.slice(1).toLowerCase() : hex.toLowerCase();
        if (!/^[0-9a-f]{6}$/.test(s))
            return null;
        return Qt.rgba(parseInt(s.slice(0, 2), 16) / 255,
                       parseInt(s.slice(2, 4), 16) / 255,
                       parseInt(s.slice(4, 6), 16) / 255, 1);
    }

    function tuneColor(hex, key) {
        const c = root.toColor(hex);
        if (!c)
            return hex;

        let hue = c.hsvHue < 0 ? 0 : c.hsvHue;
        let sat = c.hsvSaturation;
        let value = c.hsvValue;

        if (root.chromaBoost > 0.001 && !root.fidelity && root.accentRoles.indexOf(key) >= 0)
            sat = Math.min(1, sat * (1 + root.chromaBoost));

        if (Math.abs(root.contrast) > 0.001 && !root.fidelity) {
            const shift = root.contrast > 0 ? 0.06 * root.contrast : 0.09 * root.contrast;
            value = value > 0.5 ? Math.min(1, value + shift) : Math.max(0, value - shift);
        }

        return Qt.hsva(hue, sat, value, 1).toString();
    }

    function tuned(hex, key) {
        return root.tuneColor(hex, key);
    }

    function rawColor(key) {
        return colors[key];
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