import Quickshell
import QtQuick
import "bar"
import "popups"
import qs.utilities.clipboard
import qs.utilities.emoji
import qs.utilities.launcher
import qs.popups
import qs.services

ShellRoot {
    id: root

    WallpaperLayer {
        id: wallpaperLayer
    }

    LeftBar {
        id: leftBar
        launcherHandler: function() {
            if (launcherWindow.visible)
                launcherWindow.closeMenu();
            else
                launcherWindow.openMenu();
        }
    }
    BottomBar {
        id: bottomBar
    }
    RightBar {
        id: rightBar
    }

    BezelsMask {
        id: desktopBezels
    }

    TopBar {
        id: topBar
        statusPillHandler: quickSettingsWindow.toggle
    }

    NotifPopup {
        id: notificationOverlay
    }

    Clipboard {
        id: clipboardWindow
    }

    EmojiPicker {
        id: emojiPickerWindow
    }

    Launcher {
        id: launcherWindow
    }

    VolumePopup {
        id: volumePopupWindow
    }

    BrightnessPopup {
        id: brightnessPopupWindow
    }

    QuickSettings {
        id: quickSettingsWindow
        settingsHandler: settingsWindow.open
        sessionHandler: sessionWindow.open
    }

    Settings {
        id: settingsWindow
    }

    SessionPopup {
        id: sessionWindow
    }
}
