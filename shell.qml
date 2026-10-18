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
import qs.theme

ShellRoot {
    id: root

    Binding {
        target: Layout
        property: "barPosition"
        value: SettingsStore.get("barPosition")
    }

    readonly property bool idleServiceUp: Idle.caffeine !== undefined
    readonly property bool gameModeUp: GameMode.enabled !== undefined
    readonly property bool hyprUp: Hypr.usingLua !== undefined

    WallpaperLayer {
        id: wallpaperLayer
    }

    BottomBar {
        id: bottomBar
        statusPillHandler: quickSettingsWindow.toggle
    }
    LeftBar {
        id: leftBar
        statusPillHandler: quickSettingsWindow.toggle
    }
    RightBar {
        id: rightBar
        statusPillHandler: quickSettingsWindow.toggle
    }

    Chrome {
        id: desktopBezels
    }

    TopBar {
        id: topBar
        statusPillHandler: quickSettingsWindow.toggle
    }

    NotifPopup {
        id: notificationOverlay
    }

    ToastsPopup {
        id: toastOverlay
    }

    Item {
        id: qtColorsAnchor
        Component.onCompleted: {
            QtColors.writeScheme();
            Keybinds.reload();
            Targets.refresh();
        }
    }

    RegionPicker {
        id: regionPicker
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

    Dashboard {
        id: dashboardWindow
        closeSidebarHandler: quickSettingsWindow.close
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

    Component.onCompleted: NightLight.apply()
}
