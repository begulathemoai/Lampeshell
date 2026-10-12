import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import qs.theme
import qs.services

/**
 * Quick settings menu - the octashell counterpart to caelestia's command
 * center. Opened by tapping the status pill in the top bar, or via the
 * "quickSettings" IPC target.
 *
 * Anchored under the top bar on whichever monitor the pointer invoked it
 * from, matching how the pill sits at the top-right of every screen.
 */
PanelWindow {
    id: quickSettingsWindow

    implicitWidth: 400
    implicitHeight: content.implicitHeight + 36
    color: "transparent"
    visible: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quick_settings_overlay"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: -1

    anchors {
        top: true
        right: true
    }

    margins {
        top: 62
        right: 15
    }

    // Screen to anchor against; defaults to the focused output so the menu
    // opens under the bar the user actually clicked.
    property var targetScreen: {
        const active = Hyprland.focusedMonitor ?? null;
        return active && active.name ? Quickshell.screens.find(s => s.name === active.name) : Quickshell.screens[0];
    }
    screen: targetScreen

    function open() {
        quickSettingsBackend.refreshBrightness();
        quickSettingsWindow.openedAt = Date.now();
        quickSettingsWindow.grabRetries = 0;
        quickSettingsWindow.visible = true;
        // Wait for the surface to exist before grabbing focus.
        Qt.callLater(function() {
            focusGrab.active = true;
            panelBg.forceActiveFocus();
        });
    }

    // Set by shell.qml to the settings panel's open function. Declared as a
    // property because QML ids are file-scoped, so QuickSettings.qml cannot
    // reach into Settings.qml directly - the shell wires the two together the
    // same way it passes statusPillHandler to the bar.
    property var settingsHandler: null

    // Set by shell.qml to the session menu's toggle function.
    property var sessionHandler: null

    // See Settings.qml: a focus grab can lose the race with surface mapping and
    // clear immediately, which must not be mistaken for the user clicking away.
    property double openedAt: 0
    property int grabRetries: 0

    // Opening settings closes this menu first: both are Overlay-layer panels
    // anchored to the same corner, so stacking them hides one behind the other.
    function openSettings() {
        quickSettingsWindow.close();
        if (settingsHandler)
            settingsHandler();
    }

    function openSession() {
        quickSettingsWindow.close();
        if (sessionHandler)
            sessionHandler();
    }

    function close() {
        quickSettingsWindow.visible = false;
    }

    function toggle() {
        if (quickSettingsWindow.visible)
            close();
        else
            open();
    }

    QuickSettingsBackend {
        id: quickSettingsBackend
    }

    IpcHandler {
        target: "quickSettings"

        function toggle() {
            quickSettingsWindow.toggle();
        }

        function open() {
            quickSettingsWindow.open();
        }

        function close() {
            quickSettingsWindow.close();
        }

        // Opens the settings panel, closing this menu first. Exposed so the
        // gear button's handler can be exercised over IPC instead of only
        // through a mouse click.
        function settings() {
            quickSettingsWindow.openSettings();
        }

        // Opens the session/power menu, closing this menu first.
        function session() {
            quickSettingsWindow.openSession();
        }
    }

    // Dismiss on click outside the panel, mirroring the launcher/clipboard
    // behaviour. Declared first so it sits below the panel and its blocker.
    MouseArea {
        anchors.fill: parent
        onClicked: quickSettingsWindow.close()
    }

    // Clicking anywhere outside the window never reaches this surface, so the
    // MouseArea above only handles clicks on the window's own bounds. Losing
    // keyboard focus is what actually signals "clicked away" - grab focus on
    // open and close when the grab is cleared. Same approach as Clipboard.qml.
    HyprlandFocusGrab {
        id: focusGrab
        windows: [quickSettingsWindow]
        onCleared: {
            if (Date.now() - quickSettingsWindow.openedAt < 400 && quickSettingsWindow.grabRetries < 3) {
                quickSettingsWindow.grabRetries++;
                Qt.callLater(function() { focusGrab.active = true; });
                return;
            }
            quickSettingsWindow.close();
        }
    }

    // Escape closes, matching the other popups.

    // Panel chrome: rounded surface with an outline and drop shadow. The
    // window itself is transparent, so this supplies the menu's background.
    Rectangle {
        id: panelBg
        anchors.centerIn: content
        width: content.width + 36
        height: content.height + 36
        radius: Layout.cornerRadius
        color: Theme.surface_container_low
        border.width: 1
        border.color: Theme.outline_variant
        focus: true

        // Escape closes. Must live on the focused item rather than the window:
        // a PanelWindow cannot hold active focus, so window-level Keys handlers
        // never fire.
        Keys.onEscapePressed: function(event) {
            quickSettingsWindow.close();
            event.accepted = true;
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 1.0
            shadowColor: Qt.rgba(Theme.shadow.r, Theme.shadow.g, Theme.shadow.b, 0.38)
            shadowVerticalOffset: 10
        }
    }

    // Swallow clicks landing on the panel so they do not reach the dismiss
    // area behind it.
    MouseArea {
        anchors.fill: panelBg
    }

    Column {
        id: content
        anchors.centerIn: parent
        width: parent.width - 72
        spacing: 14

        // --- Header: connectivity summary ---
        Row {
            width: parent.width
            spacing: 18
            visible: quickSettingsBackend.batteryPresent

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: quickSettingsBackend.batteryIcon()
                color: quickSettingsBackend.batteryPct < 20 && !quickSettingsBackend.batteryCharging ? Theme.critical : Theme.on_surface
                font {
                    family: "Material Symbols Rounded"
                    pixelSize: 26
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: quickSettingsBackend.batteryLabel()
                color: Theme.on_surface
                font {
                    family: "Google Sans"
                    pixelSize: 14
                    weight: Font.Medium
                }
            }
        }

        // --- Quick toggles ---
        Row {
            width: parent.width
            spacing: 12

            Repeater {
                model: 3

                delegate: Item {
                    id: tile
                    required property int index
                    width: (content.width - 24) / 3
                    height: 76

                    readonly property bool toggleOn: {
                        if (index === 0)
                            // Radio state, not "is a network connected".
                            return quickSettingsBackend.wifiEnabled;
                        if (index === 1)
                            return quickSettingsBackend.btPowered;
                        return !quickSettingsBackend.isMuted;
                    }

                    readonly property string iconName: {
                        if (index === 0) {
                            return quickSettingsBackend.wifiEnabled ? "wifi" : "wifi_off";
                        }
                        if (index === 1)
                            return quickSettingsBackend.btPowered ? "bluetooth" : "bluetooth_disabled";
                        return quickSettingsBackend.isMuted ? "volume_off" : "volume_up";
                    }

                    readonly property string labelText: index === 0 ? "Wi-Fi" : (index === 1 ? "Bluetooth" : "Sound")

                    Rectangle {
                        id: tileBg
                        anchors.fill: parent
                        radius: 22

                        color: tile.toggleOn
                            ? Theme.primary_container
                            : (tileMouse.containsMouse
                                ? Qt.tint(Theme.surface_container_high, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08))
                                : Theme.surface_container)

                        scale: tileMouse.pressed ? 0.95 : 1.0
                        transformOrigin: Item.Center

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.iconName
                            color: tile.toggleOn ? Theme.on_primary_container : Theme.on_surface
                            font {
                                family: "Material Symbols Rounded"
                                pixelSize: 24
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.labelText
                            color: tile.toggleOn ? Theme.on_primary_container : Theme.on_surface_variant
                            font {
                                family: "Google Sans"
                                pixelSize: 12
                                weight: Font.Medium
                            }
                        }
                    }

                    MouseArea {
                        id: tileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            if (tile.index === 0)
                                quickSettingsBackend.toggleWifi();
                            else if (tile.index === 1)
                                quickSettingsBackend.toggleBluetooth();
                            else
                                quickSettingsBackend.toggleMute();
                        }
                    }
                }
            }
        }

        // --- Volume slider ---
        Rectangle {
            width: parent.width
            height: 64
            radius: 22
            color: Theme.surface_container_highest

            Row {
                id: volumeRow
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 14

                MouseArea {
                    id: muteButton
                    width: 32
                    height: 32
                    anchors.verticalCenter: parent.verticalCenter
                    cursorShape: Qt.PointingHandCursor

                    Text {
                        anchors.centerIn: parent
                        text: quickSettingsBackend.isMuted ? "volume_off" : "volume_up"
                        color: quickSettingsBackend.isMuted ? Theme.critical : Theme.on_surface
                        font {
                            family: "Material Symbols Rounded"
                            pixelSize: 24
                        }
                    }

                    onClicked: quickSettingsBackend.toggleMute()
                }

                // Slider track + fill
                Rectangle {
                    id: volumeTrack
                    // Row has three children (icon, track, label) and two gaps,
                    // so subtract the icon AND label widths plus both spacings.
                    width: parent.width - muteButton.width - volumePercentLabel.width - parent.spacing * 2
                    height: 6
                    radius: 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.surface_container_high

                    Rectangle {
                        width: volumeTrack.width * quickSettingsBackend.volumeLevel
                        height: parent.height
                        radius: parent.radius
                        color: quickSettingsBackend.isMuted ? Theme.outline : Theme.primary

                        Behavior on width {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    MouseArea {
                        id: volumeDrag
                        anchors.fill: parent
                        anchors.margins: -14
                        cursorShape: Qt.PointingHandCursor

                        function positionToFraction(mx) {
                            return Math.max(0, Math.min(1, mx / volumeTrack.width));
                        }

                        onPressed: mouse => quickSettingsBackend.setVolume(positionToFraction(mouse.x))
                        onPositionChanged: mouse => {
                            if (pressed)
                                quickSettingsBackend.setVolume(positionToFraction(mouse.x));
                        }
                    }
                }

                Text {
                    id: volumePercentLabel
                    width: 34
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignRight
                    text: quickSettingsBackend.volumePercent + "%"
                    color: Theme.on_surface_variant
                    font {
                        family: "Google Sans"
                        pixelSize: 12
                        weight: Font.Medium
                    }
                }
            }
        }

        // --- Brightness slider ---
        Rectangle {
            width: parent.width
            height: 64
            radius: 22
            color: Theme.surface_container_highest

            Row {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 14

                Text {
                    id: brightnessIcon
                    width: 32
                    height: 32
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: quickSettingsBackend.brightnessLevel >= 0.7 ? "brightness_high" : (quickSettingsBackend.brightnessLevel >= 0.3 ? "brightness_medium" : "brightness_low")
                    color: Theme.on_surface
                    font {
                        family: "Material Symbols Rounded"
                        pixelSize: 24
                    }
                }

                Rectangle {
                    id: brightnessTrack
                    width: parent.width - brightnessIcon.width - brightnessPercentLabel.width - parent.spacing * 2
                    height: 6
                    radius: 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.surface_container_high

                    Rectangle {
                        width: brightnessTrack.width * quickSettingsBackend.brightnessLevel
                        height: parent.height
                        radius: parent.radius
                        color: Theme.primary

                        Behavior on width {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    MouseArea {
                        id: brightnessDrag
                        anchors.fill: parent
                        anchors.margins: -14
                        cursorShape: Qt.PointingHandCursor

                        function positionToFraction(mx) {
                            return Math.max(0, Math.min(1, mx / brightnessTrack.width));
                        }

                        onPressed: mouse => quickSettingsBackend.setBrightness(positionToFraction(mouse.x))
                        onPositionChanged: mouse => {
                            if (pressed)
                                quickSettingsBackend.setBrightness(positionToFraction(mouse.x));
                        }
                    }
                }

                Text {
                    id: brightnessPercentLabel
                    width: 34
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(quickSettingsBackend.brightnessLevel * 100) + "%"
                    color: Theme.on_surface_variant
                    font {
                        family: "Google Sans"
                        pixelSize: 12
                        weight: Font.Medium
                    }
                }
            }
        }

        // --- Network list ---
        Rectangle {
            width: parent.width
            height: Math.max(64, netColumn.implicitHeight + 28)
            radius: 22
            color: Theme.surface_container_highest
            visible: quickSettingsBackend.visibleNetworks.length > 0

            Column {
                id: netColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 4

                Repeater {
                    id: netRepeater
                    model: quickSettingsBackend.visibleNetworks

                    delegate: Item {
                        id: netRow
                        required property var modelData

                        width: netColumn.width
                        height: 44

                        // Referenced through netRow rather than parent chains:
                        // inside the nested Row/Column, parent.parent resolves to
                        // the Row, not the delegate.
                        readonly property bool isConnected: modelData.connected === true
                        readonly property string netName: {
                            if (!modelData)
                                return "Unknown";
                            return modelData.name ?? modelData.ssid ?? "Unknown";
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: netMouse.containsMouse
                                ? Qt.tint(Theme.surface_container_high, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08))
                                : "transparent"
                        }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 14

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: netRow.isConnected ? "wifi" : "wifi_off"
                                color: netRow.isConnected ? Theme.primary : Theme.on_surface_variant
                                font {
                                    family: "Material Symbols Rounded"
                                    pixelSize: 20
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1

                                Text {
                                    text: netRow.netName
                                    color: Theme.on_surface
                                    font {
                                        family: "Google Sans"
                                        pixelSize: 13
                                        weight: Font.Medium
                                    }
                                }

                                Text {
                                    visible: netRow.isConnected
                                    text: "Connected"
                                    color: Theme.primary
                                    font {
                                        family: "Google Sans"
                                        pixelSize: 11
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            text: netRow.isConnected ? "check" : "arrow_forward"
                            color: Theme.on_surface_variant
                            font {
                                family: "Material Symbols Rounded"
                                pixelSize: 18
                            }
                        }

                        MouseArea {
                            id: netMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: quickSettingsBackend.toggleNetwork(netRow.modelData)
                        }
                    }
                }
            }
        }

        // --- Footer: settings + session entries ---
        Row {
            width: parent.width
            spacing: 10

            Rectangle {
                id: sessionTile
                width: 46
                height: 46
                radius: 22
                color: sessionMouse.containsMouse
                    ? Qt.tint(Theme.surface_container_highest, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.10))
                    : Theme.surface_container_highest

                Text {
                    anchors.centerIn: parent
                    text: "power_settings_new"
                    color: Theme.on_surface
                    font {
                        family: "Material Symbols Rounded"
                        pixelSize: 20
                    }
                }

                MouseArea {
                    id: sessionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: quickSettingsWindow.openSession()
                }
            }

            Rectangle {
                id: gearTile
                width: parent.width - sessionTile.width - 10
                height: 46
                radius: 22
                color: gearMouse.containsMouse
                    ? Qt.tint(Theme.surface_container_highest, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.10))
                    : Theme.surface_container_highest

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "settings"
                        color: Theme.on_surface
                        font {
                            family: "Material Symbols Rounded"
                            pixelSize: 20
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Shell settings"
                        color: Theme.on_surface
                        font {
                            family: "Google Sans"
                            pixelSize: 13
                            weight: Font.Medium
                        }
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    text: "chevron_right"
                    color: Theme.on_surface_variant
                    font {
                        family: "Material Symbols Rounded"
                        pixelSize: 18
                    }
                }

                MouseArea {
                    id: gearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: quickSettingsWindow.openSettings()
                }
            }
        }
    }
}
