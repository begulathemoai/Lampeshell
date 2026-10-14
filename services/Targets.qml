pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.theme

Item {
    id: root

    implicitWidth: 0
    implicitHeight: 0

    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string mergeScript: Quickshell.shellPath("scripts/theme-merge")

    readonly property string gtk4Path: homeDir + "/.config/gtk-4.0/gtk.css"
    readonly property string gtk3Path: homeDir + "/.config/gtk-3.0/gtk.css"
    readonly property string schemePath: homeDir + "/.config/hypr/scheme/current.lua"

    readonly property var targets: [
        {
            key: "gtk4",
            label: "GTK 4 apps",
            description: "Files, preferences and libadwaita apps"
        },
        {
            key: "gtk3",
            label: "GTK 3 apps",
            description: "Older GTK toolkits"
        },
        {
            key: "hypr",
            label: "Compositor borders",
            description: "Focused and unfocused window outlines"
        },
        {
            key: "hyprScheme",
            label: "Hyprland colour scheme",
            description: "~/.config/hypr/scheme/current.lua"
        }
    ]

    FileView {
        id: gtk4File

        path: root.gtk4Path
        blockLoading: true
    }

    FileView {
        id: gtk3File

        path: root.gtk3Path
        blockLoading: true
    }

    FileView {
        id: schemeFile

        path: root.schemePath
        blockLoading: true
    }

    function exists(key) {
        if (key === "hypr")
            return true;

        const file = {
            gtk4: gtk4File,
            gtk3: gtk3File,
            hyprScheme: schemeFile
        }[key];

        if (!file)
            return false;

        const text = file.text();
        return text !== undefined && text !== null && text.length > 0;
    }

    function enabled(key) {
        return SettingsStore.loaded && SettingsStore.get("themeTarget" + key) === true;
    }

    function hex(role) {
        const c = Theme[role];
        if (!c)
            return null;
        const s = String(c).replace("#", "").toLowerCase();
        return /^[0-9a-f]{6}$/.test(s) ? s : null;
    }

    function pack(v) {
        const n = Math.round(v);
        const c = n < 0 ? 0 : (n > 255 ? 255 : n);
        return c.toString(16).padStart(2, "0");
    }

    function toHex(r, g, b) {
        return root.pack(r) + root.pack(g) + root.pack(b);
    }

    function snake(name) {
        return name.replace(/([a-z0-9])([A-Z])/g, "$1_$2").toLowerCase();
    }

    function shift(value, dh, ds, dl) {
        if (!value)
            return null;

        const r = parseInt(value.slice(0, 2), 16) / 255;
        const g = parseInt(value.slice(2, 4), 16) / 255;
        const b = parseInt(value.slice(4, 6), 16) / 255;
        const mx = Math.max(r, g, b);
        const mn = Math.min(r, g, b);
        let l = (mx + mn) / 2;

        let h = 0;
        let s = 0;

        if (mx !== mn) {
            const d = mx - mn;
            s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn);
            if (mx === r)
                h = (g - b) / d + (g < b ? 6 : 0);
            else if (mx === g)
                h = (b - r) / d + 2;
            else
                h = (r - g) / d + 4;
            h *= 60;
        }

        if (dh)
            h = (h + dh + 360) % 360;
        if (ds)
            s = Math.max(0, Math.min(1, s * ds));
        if (dl)
            l = Math.max(0, Math.min(1, l + dl));

        l = Math.max(0.07, Math.min(0.9, l));

        if (s <= 0)
            return toHex(l * 255, l * 255, l * 255);

        const c = (1 - Math.abs(2 * l - 1)) * s;
        const x = c * (1 - Math.abs((h / 60) % 2 - 1));
        const m = l - c / 2;

        let r1, g1, b1;
        if (h < 60) { r1 = c; g1 = x; b1 = 0; }
        else if (h < 120) { r1 = x; g1 = c; b1 = 0; }
        else if (h < 180) { r1 = 0; g1 = c; b1 = x; }
        else if (h < 240) { r1 = 0; g1 = x; b1 = c; }
        else if (h < 300) { r1 = x; g1 = 0; b1 = c; }
        else { r1 = c; g1 = 0; b1 = x; }

        return toHex((r1 + m) * 255, (g1 + m) * 255, (b1 + m) * 255);
    }

    readonly property var gtkRoles: [
        ["accent_color", "primary"],
        ["accent_fg_color", "on_primary"],
        ["accent_bg_color", "primary"],
        ["window_bg_color", "background"],
        ["window_fg_color", "on_background"],
        ["headerbar_bg_color", "surface_dim"],
        ["headerbar_fg_color", "on_surface"],
        ["popover_bg_color", "surface_dim"],
        ["popover_fg_color", "on_surface"],
        ["view_bg_color", "surface"],
        ["view_fg_color", "on_surface"],
        ["card_bg_color", "surface"],
        ["card_fg_color", "on_surface"]
    ]

    readonly property var gtkAliases: [
        "@define-color sidebar_bg_color @window_bg_color;",
        "@define-color sidebar_fg_color @window_fg_color;",
        "@define-color sidebar_border_color @window_bg_color;",
        "@define-color sidebar_backdrop_color @window_bg_color;",
        "@define-color theme_selected_bg_color alpha(@accent_color, 0.15);",
        "@define-color theme_selected_fg_color @primary;"
    ]

    function gtkBlock() {
        const out = [];

        for (let i = 0; i < gtkRoles.length; i++) {
            const value = root.hex(gtkRoles[i][1]);
            if (!value)
                return [];
            out.push("@define-color " + gtkRoles[i][0] + " #" + value + ";");
        }

        for (let i = 0; i < gtkAliases.length; i++)
            out.push(gtkAliases[i]);

        return out;
    }

    readonly property var m3Keys: [
        "background", "onBackground", "surface", "surfaceDim", "surfaceBright",
        "surfaceContainerLowest", "surfaceContainerLow", "surfaceContainer",
        "surfaceContainerHigh", "surfaceContainerHighest", "onSurface",
        "surfaceVariant", "onSurfaceVariant", "outline", "outlineVariant",
        "inverseSurface", "inverseOnSurface", "shadow", "scrim", "surfaceTint",
        "primary", "primaryDim", "onPrimary", "primaryContainer",
        "onPrimaryContainer", "inversePrimary", "primaryFixed", "primaryFixedDim",
        "onPrimaryFixed", "onPrimaryFixedVariant", "secondary", "secondaryDim",
        "onSecondary", "secondaryContainer", "onSecondaryContainer",
        "secondaryFixed", "secondaryFixedDim", "onSecondaryFixed",
        "onSecondaryFixedVariant", "tertiary", "tertiaryDim", "onTertiary",
        "tertiaryContainer", "onTertiaryContainer", "tertiaryFixed",
        "tertiaryFixedDim", "onTertiaryFixed", "onTertiaryFixedVariant",
        "error", "errorDim", "onError", "errorContainer", "onErrorContainer",
        "primaryPaletteKeyColor", "secondaryPaletteKeyColor",
        "tertiaryPaletteKeyColor", "neutralPaletteKeyColor",
        "neutralVariantPaletteKeyColor", "errorPaletteKeyColor",
        "primary_paletteKeyColor", "secondary_paletteKeyColor",
        "tertiary_paletteKeyColor", "neutral_paletteKeyColor",
        "neutral_variant_paletteKeyColor"
    ]

    readonly property var m3Alias: {
        return {
            primaryDim: "primary_fixed_dim",
            secondaryDim: "secondary_fixed_dim",
            tertiaryDim: "tertiary_fixed_dim"
        };
    }

    readonly property var m3Derived: {
        return {
            errorDim: ["error", 0, 1, -0.05],
            primaryPaletteKeyColor: ["primary", 0, 1, 0],
            secondaryPaletteKeyColor: ["secondary", 0, 1, 0],
            tertiaryPaletteKeyColor: ["tertiary", 0, 1, 0],
            errorPaletteKeyColor: ["error", 0, 1, 0],
            neutralPaletteKeyColor: ["primary", 0, 0.18, -0.14],
            neutralVariantPaletteKeyColor: ["primary", 0, 0.12, -0.08],
            primary_paletteKeyColor: ["primary", 0, 1, 0],
            secondary_paletteKeyColor: ["secondary", 0, 1, 0],
            tertiary_paletteKeyColor: ["tertiary", 0, 1, 0],
            neutral_paletteKeyColor: ["primary", 0, 0.18, -0.14],
            neutral_variant_paletteKeyColor: ["primary", 0, 0.12, -0.08]
        };
    }

    readonly property var accentKeys: {
        return {
            rosewater: ["primary", 340, 1, 0.12],
            flamingo: ["primary", 310, 1, 0.08],
            pink: ["primary", 285, 1, 0.08],
            mauve: ["primary", -25, 1, 0.02],
            red: "error",
            maroon: ["error", 0, 1, -0.05],
            peach: ["primary", 55, 1, 0.08],
            yellow: ["primary", 80, 1, 0.08],
            green: ["primary", 135, 1, 0.02],
            teal: ["primary", 175, 1, 0.02],
            sky: ["primary", 205, 1, 0.02],
            sapphire: ["primary", 235, 1, 0.02],
            blue: "secondary",
            lavender: ["primary", 270, 1, 0.06]
        };
    }

    readonly property var surfaceKeys: {
        return {
            klink: "secondary",
            klinkSelection: "surface_container_highest",
            kvisited: "tertiary",
            kvisitedSelection: "surface_container_high",
            knegative: "error",
            knegativeSelection: "surface_container_high",
            kneutral: "on_surface_variant",
            kneutralSelection: "surface_container_high",
            kpositive: "primary",
            kpositiveSelection: "surface_container_high",
            text: "on_surface",
            subtext1: "on_surface_variant",
            subtext0: "outline",
            overlay2: "surface_container_lowest",
            overlay1: "surface_container_low",
            overlay0: "surface_container",
            surface2: "surface_container_high",
            surface1: "surface_container",
            surface0: "surface_dim",
            base: "surface",
            mantle: "surface_bright",
            crust: "surface_container_lowest",
            onSuccess: "on_surface",
            onSuccessContainer: "on_surface_variant"
        };
    }

    readonly property var successKeys: {
        return {
            success: ["primary", 135, 1, 0.02],
            successContainer: ["primary", 135, 0.6, -0.16]
        };
    }

    function schemeMap() {
        const map = {};

        const put = (k, v) => {
            if (typeof v === "string" && /^[0-9a-f]{6}$/.test(v))
                map[k] = v;
        };

        for (let i = 0; i < m3Keys.length; i++) {
            const key = m3Keys[i];

            if (key in m3Alias) {
                put(key, root.hex(m3Alias[key]));
                continue;
            }

            if (key in m3Derived) {
                const d = m3Derived[key];
                const source = root.hex(d[0]);
                if (source)
                    put(key, root.shift(source, d[1], d[2], d[3]));
                continue;
            }

            put(key, root.hex(root.snake(key)));
        }

        const terms = ThemeService.terminalPalette(root.hex("primary"));
        if (terms && terms.length === 16) {
            for (let i = 0; i < 16; i++)
                put("term" + i, terms[i]);
        }

        for (const k in accentKeys) {
            const v = accentKeys[k];
            const source = root.hex(typeof v === "string" ? v : v[0]);
            if (source)
                put(k, typeof v === "string" ? v : root.shift(source, v[1], v[2], v[3]));
        }

        for (const k in successKeys) {
            const d = successKeys[k];
            const source = root.hex(d[0]);
            if (source)
                put(k, root.shift(source, d[1], d[2], d[3]));
        }

        for (const k in surfaceKeys)
            put(k, root.hex(surfaceKeys[k]));

        return map;
    }

    function schemeBlock() {
        const map = schemeMap();
        const out = [];

        for (const k in map)
            out.push("  " + k + " = \"" + map[k] + "\",");

        return out;
    }

    function rgba(role, alpha) {
        const value = hex(role);
        return value ? "rgba(" + value + alpha + ")" : null;
    }

    function applyHypr() {
        const active = rgba("primary", "e6");
        const inactive = rgba("on_surface_variant", "11");
        if (!active || !inactive)
            return;

        if (Hypr.usingLua) {
            Quickshell.execDetached([
                "hyprctl", "eval",
                'hl.config({ general = { col = { active_border = "' + active
                    + '", inactive_border = "' + inactive + '" } } })'
            ]);
        } else {
            Quickshell.execDetached([
                "hyprctl", "keyword", "col.active_border", active,
                "1", "col.inactive_border", inactive
            ]);
        }
    }

    function applyFiles(mode, path, lines) {
        if (!lines || lines.length === 0)
            return;
        Quickshell.execDetached([mergeScript, mode, path].concat(lines));
    }

    function refresh() {
        if (!SettingsStore.loaded)
            return;

        if (enabled("gtk4"))
            applyFiles("css", gtk4Path, gtkBlock());

        if (enabled("gtk3"))
            applyFiles("css", gtk3Path, gtkBlock());

        if (enabled("hyprScheme"))
            applyFiles("lua", schemePath, schemeBlock());

        if (enabled("hypr"))
            applyHypr();
    }

    Timer {
        id: debounce

        interval: 400

        onTriggered: root.refresh()
    }

    Connections {
        target: ThemeService

        function onPaletteApplied(): void {
            debounce.restart();
        }
    }

    Connections {
        target: Hypr

        function onConfigReloaded(): void {
            debounce.restart();
        }
    }

    Connections {
        target: SettingsStore

        function onValuesChanged(): void {
            if (SettingsStore.loaded)
                debounce.restart();
        }

        function onLoadedChanged(): void {
            if (SettingsStore.loaded)
                debounce.restart();
        }
    }
}