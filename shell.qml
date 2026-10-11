//@ pragma IconTheme Papirus
//@ pragma UseQApplication

import Quickshell
import QtQuick
import "bar"
import "popups"
import qs.utilities.clipboard
import qs.utilities.emoji
import qs.utilities.launcher
import qs.popups
import qs.services

/** Main shell entry point; manages surface orchestration. */
ShellRoot {
    id: root

    // Wallpaper first and on the Bottom layer: it has to be under everything
    WallpaperLayer {
        id: wallpaperLayer
    }

    // Primary desktop bars
    LeftBar {
        id: leftBar
    }
    BottomBar {
        id: bottomBar
    }
    RightBar {
        id: rightBar
    }

    // Screen masking for rounded workspace effect
    BezelsMask {
        id: desktopBezels
    }

    // System status bar
    TopBar {
        id: topBar
        statusPillHandler: quickSettingsWindow.toggle
    }

    // Floating notification overlay
    NotifPopup {
        id: notificationOverlay
    }

    // Clipboard
    Clipboard {
        id: clipboardWindow
    }

    // Emoji Picker
    EmojiPicker {
        id: emojiPickerWindow
    }

    // Application Launcher
    Launcher {
        id: launcherWindow
    }

    VolumePopup {
        id: volumePopupWindow
    }

    BrightnessPopup {
        id: brightnessPopupWindow
    }

    // Quick settings menu (wifi / bluetooth / volume / brightness / networks)
    QuickSettings {
        id: quickSettingsWindow
        settingsHandler: settingsWindow.open
    }

    // Shell settings panel (accent colour, live theme editing)
    Settings {
        id: settingsWindow
    }

    // Session / power menu
    SessionPopup {
        id: sessionWindow
    }
}
