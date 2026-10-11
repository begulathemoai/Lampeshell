pragma Singleton

import QtQuick

/**
 * The ordered list of settings sections.
 *
 * PageCompRegistry holds a component at the same index for every entry here, and
 * the nav pane groups rows by `category`, so the three must be kept in step. A
 * `description` is optional; the nav row just omits it.
 */
QtObject {
    readonly property list<var> pages: [
        {
            label: "Appearance",
            icon: "palette",
            description: "Accent colour and wallpaper",
            category: "personal"
        },
        {
            label: "Display",
            icon: "brightness_6",
            description: "Brightness per output",
            category: "personal"
        },
        {
            label: "Panels",
            icon: "dock_to_bottom",
            description: "Bars, tray and status items",
            category: "personal"
        },

        {
            label: "Audio",
            icon: "volume_up",
            description: "Output, input and app volumes",
            category: "connectivity"
        },
        {
            label: "Network",
            icon: "wifi",
            description: "Wi-Fi and saved networks",
            category: "connectivity"
        },
        {
            label: "Bluetooth",
            icon: "bluetooth",
            description: "Adapter and paired devices",
            category: "connectivity"
        },

        {
            label: "Services",
            icon: "build",
            description: "Notifications and shell integrations",
            category: "system"
        },
        {
            label: "Language & region",
            icon: "globe",
            description: "Locale, formats and timezone",
            category: "system"
        },

        {
            label: "About",
            icon: "info",
            description: "System information and credits",
            category: "about"
        }
    ]
}
