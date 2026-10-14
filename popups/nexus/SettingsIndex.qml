pragma Singleton

import QtQuick

QtObject {
    readonly property list<var> entries: [
        {
            page: "Appearance",
            title: "Dynamic colour",
            desc: "Follow the wallpaper accent",
            icon: "auto_awesome",
            keywords: "theme colors accent wallpaper dynamic material you"
        },
        {
            page: "Appearance",
            title: "Custom colour",
            desc: "Pick your own accent",
            icon: "palette",
            keywords: "personalised accent custom color"
        },
        {
            page: "Appearance",
            title: "Pick colour from wallpaper",
            desc: "Sample a point on the image",
            icon: "colorize",
            keywords: "eyedropper sample wallpaper color"
        },
        {
            page: "Appearance",
            title: "Colour picker",
            desc: "Choose a colour manually",
            icon: "palette",
            keywords: "hue saturation lightness color"
        },
        {
            page: "Appearance",
            title: "Theme Style",
            desc: "Material You palette style",
            icon: "palette",
            keywords: "material you scheme style"
        },
        {
            page: "Appearance",
            title: "Fidelity",
            desc: "Use the source colour as the accent",
            icon: "tune",
            keywords: "exact accent source"
        },
        {
            page: "Appearance",
            title: "Contrast Level",
            desc: "How strongly tones separate",
            icon: "contrast",
            keywords: "contrast tone"
        },
        {
            page: "Appearance",
            title: "Chroma Boost",
            desc: "Colour intensity",
            icon: "tonality",
            keywords: "chroma saturation boost"
        },
        {
            page: "Appearance",
            title: "Wallpaper",
            desc: "Choose a wallpaper",
            icon: "wallpaper",
            keywords: "background image wallpaper",
            subPage: 1
        },

        {
            page: "Display",
            title: "Brightness",
            desc: "Screen backlight",
            icon: "brightness_6",
            keywords: "backlight luminance display"
        },
        {
            page: "Display",
            title: "Night light",
            desc: "Blue light filter",
            icon: "light_mode",
            keywords: "nightlight blue light warm temperature"
        },
        {
            page: "Display",
            title: "Night light temperature",
            desc: "Warmth in kelvin",
            icon: "thermostat",
            keywords: "kelvin warm nightlight"
        },
        {
            page: "Display",
            title: "Night light method",
            desc: "Auto, Display, Gamma or Shader",
            icon: "settings",
            keywords: "ddc gamma shader auto backend nightlight"
        },
        {
            page: "Display",
            title: "Night light status",
            desc: "Filter state",
            icon: "info",
            keywords: "nightlight status"
        },

        {
            page: "Panels",
            title: "Top bar height",
            desc: "Bar thickness",
            icon: "dock_to_bottom",
            keywords: "bar height panel"
        },
        {
            page: "Panels",
            title: "Workspace slots",
            desc: "Workspaces shown in the bar",
            icon: "view_week",
            keywords: "workspaces bar"
        },
        {
            page: "Panels",
            title: "Clock",
            desc: "Bar clock position",
            icon: "schedule",
            keywords: "clock time bar"
        },
        {
            page: "Panels",
            title: "Tray and status",
            desc: "Status area position",
            icon: "view_agenda",
            keywords: "tray status system icons bar"
        },

        {
            page: "Audio",
            title: "Output volume",
            desc: "Default speaker volume",
            icon: "volume_up",
            keywords: "volume sound sink speaker output"
        },
        {
            page: "Audio",
            title: "Output devices",
            desc: "Pick a speaker",
            icon: "speaker",
            keywords: "sink output device speaker"
        },
        {
            page: "Audio",
            title: "Input volume",
            desc: "Microphone level",
            icon: "mic",
            keywords: "microphone input source volume"
        },
        {
            page: "Audio",
            title: "Input devices",
            desc: "Pick a microphone",
            icon: "mic",
            keywords: "source input device microphone"
        },
        {
            page: "Audio",
            title: "Applications",
            desc: "Per-app volumes",
            icon: "apps",
            keywords: "app stream volume per-app"
        },

        {
            page: "Network",
            title: "Wi-Fi",
            desc: "Wireless radio",
            icon: "wifi",
            keywords: "wifi wireless network radio"
        },
        {
            page: "Network",
            title: "Wired",
            desc: "Ethernet interfaces",
            icon: "lan",
            keywords: "ethernet wired lan"
        },
        {
            page: "Network",
            title: "Saved networks",
            desc: "Known Wi-Fi networks",
            icon: "wifi",
            keywords: "saved networks wifi connect"
        },

        {
            page: "Bluetooth",
            title: "Bluetooth",
            desc: "Adapter radio",
            icon: "bluetooth",
            keywords: "bluetooth adapter radio"
        },
        {
            page: "Bluetooth",
            title: "Discoverable",
            desc: "Scan for nearby devices",
            icon: "radar",
            keywords: "discovering scan bluetooth"
        },
        {
            page: "Bluetooth",
            title: "Paired devices",
            desc: "Connected devices",
            icon: "devices",
            keywords: "paired devices bluetooth"
        },
        {
            page: "Bluetooth",
            title: "Available devices",
            desc: "Nearby devices to pair",
            icon: "bluetooth_searching",
            keywords: "available devices pair bluetooth"
        },
        {
            page: "Bluetooth",
            title: "Open blueman-manager",
            desc: "Troubleshooting tool",
            icon: "bluetooth_audio",
            keywords: "blueman troubleshooting bluetooth"
        },

        {
            page: "Services",
            title: "Adapter powered",
            desc: "Bluetooth radio power",
            icon: "power_settings_new",
            keywords: "bluetooth adapter power services"
        },

        {
            page: "Notifications",
            title: "Enable DND",
            desc: "Do not disturb",
            icon: "notifications_off",
            keywords: "do not disturb dnd notifications"
        },
        {
            page: "Notifications",
            title: "Default timeout",
            desc: "Popup duration",
            icon: "timer",
            keywords: "timeout notifications popup"
        },
        {
            page: "Notifications",
            title: "Fullscreen timeout",
            desc: "Popup duration in fullscreen",
            icon: "timer",
            keywords: "timeout fullscreen notifications"
        },

        {
            page: "Language & region",
            title: "Locale",
            desc: "Language and formats",
            icon: "language",
            keywords: "locale language region"
        },
        {
            page: "Language & region",
            title: "Timezone",
            desc: "System time zone",
            icon: "schedule",
            keywords: "timezone time zone region"
        },
        {
            page: "Language & region",
            title: "24-hour clock",
            desc: "Time format",
            icon: "schedule",
            keywords: "clock 24 hour format region"
        },

        {
            page: "About",
            title: "Compositor",
            desc: "Hyprland version",
            icon: "info",
            keywords: "hyprland compositor version about"
        },
        {
            page: "About",
            title: "Shell",
            desc: "lampshell and quickshell version",
            icon: "info",
            keywords: "quickshell version about"
        },
        {
            page: "About",
            title: "Session",
            desc: "Display resolution",
            icon: "monitor",
            keywords: "monitor resolution session about"
        }
    ]
}
