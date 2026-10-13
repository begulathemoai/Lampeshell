import Quickshell
import Quickshell.Hyprland
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


    GlobalShortcut {
        appid: "lampshell"
        name: "appLauncher"
        description: "Toggle launcher"
        onReleased: {
            if (launcherWindow.visible)
                launcherWindow.closeMenu();
            else
                launcherWindow.openMenu();
        }
    }

    GlobalShortcut {
        appid: "lampshell"
        name: "session"
        description: "Toggle session menu"
        onPressed: sessionWindow.toggle()
    }

    GlobalShortcut {
        appid: "lampshell"
        name: "quickSettings"
        description: "Toggle quick settings"
        onPressed: quickSettingsWindow.toggle()
    }

    GlobalShortcut {
        appid: "lampshell"
        name: "lock"
        description: "Lock the session"
        onPressed: sessionWindow.lock()
    }
}
