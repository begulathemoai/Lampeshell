import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import qs.theme
import qs.services
import qs.popups.settings

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
        top: Layout.topBarHeight
        right: 0
    }

    property var targetScreen: {
        const active = Hyprland.focusedMonitor ?? null;
        return active && active.name ? Quickshell.screens.find(s => s.name === active.name) : Quickshell.screens[0];
    }
    screen: targetScreen

    function open() {
        quickSettingsBackend.refreshBrightness();
        quickSettingsWindow.openedAt = Date.now();
        quickSettingsWindow.settling = true;
        settleTimer.restart();
        quickSettingsWindow.visible = true;

        Qt.callLater(function() {
            focusGrab.active = true;
            panelBg.forceActiveFocus();
        });
        if (quickSettingsWindow.shown) {
            quickSettingsWindow.openedAt = Date.now();
        } else {
            showKick.restart();
        }
    }

    property var settingsHandler: null

    property var sessionHandler: null

    property double openedAt: 0

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
        quickSettingsWindow.shown = false;
        PanelState.merged = false;
        focusGrab.active = false;
        hideWhenDone.restart();
    }

    function toggle() {
        if (quickSettingsWindow.shown || quickSettingsWindow.visible)
            close();
        else
            open();
    }

    property bool shown: false

    onShownChanged: panelBg.slideOffset = shown ? 0 : 1;

    property bool settling: false

    Timer {
        id: settleTimer
        interval: 700
        onTriggered: quickSettingsWindow.settling = false
    }

    Timer {
        id: showKick
        interval: 1
        onTriggered: {
            quickSettingsWindow.shown = true;
            PanelState.merged = true;
        }
    }

    Timer {
        id: hideWhenDone
        interval: 460
        onTriggered: {
            if (!quickSettingsWindow.shown)
                quickSettingsWindow.visible = false;
        }
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

        function settings() {
            quickSettingsWindow.openSettings();
        }

        function session() {
            quickSettingsWindow.openSession();
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: quickSettingsWindow.close()
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [quickSettingsWindow]
        onCleared: {
            if (quickSettingsWindow.settling) {
                Qt.callLater(function() { focusGrab.active = true; });
                return;
            }
            quickSettingsWindow.close();
        }
    }

    Rectangle {
        id: panelBg
        anchors.left: parent.left
        anchors.leftMargin: Layout.s(18)
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        radius: Layout.cornerRadius

        color: Theme.surface_container_lowest
        focus: true

        property real slideOffset: 1

        transform: Translate {
            x: panelBg.slideOffset * Layout.s(28)
        }
        opacity: Math.max(0, 1 - panelBg.slideOffset)

        Behavior on slideOffset {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutCubic
            }
        }


        Keys.onEscapePressed: function(event) {
            quickSettingsWindow.close();
            event.accepted = true;
        }
    }

    MouseArea {
        anchors.fill: panelBg
    }

    Column {
        id: content
        anchors.top: parent.top
        anchors.topMargin: 18
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
        anchors.left: parent.left
        anchors.leftMargin: Layout.s(36)
        anchors.right: parent.right
        anchors.rightMargin: Layout.s(18)
        spacing: 14

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

        Row {
            width: parent.width
            spacing: 12

            Repeater {
                model: 4

                delegate: Item {
                    id: tile
                    required property int index
                    width: (content.width - 36) / 4
                    height: Layout.s(76)

                    readonly property bool toggleOn: {
                        if (index === 0)

                            return quickSettingsBackend.wifiEnabled;
                        if (index === 1)
                            return quickSettingsBackend.btPowered;
                        if (index === 2)
                            return !quickSettingsBackend.isMuted;
                        return Idle.caffeine;
                    }

                    readonly property string iconName: {
                        if (index === 0) {
                            return quickSettingsBackend.wifiEnabled ? "wifi" : "wifi_off";
                        }
                        if (index === 1)
                            return quickSettingsBackend.btPowered ? "bluetooth" : "bluetooth_disabled";
                        if (index === 2)
                            return quickSettingsBackend.isMuted ? "volume_off" : "volume_up";
                        return Idle.caffeine ? "local_cafe" : "coffee";
                    }

                    readonly property string labelText: index === 0 ? "Wi-Fi"
                        : (index === 1 ? "Bluetooth" : (index === 2 ? "Sound" : "Caffeine"))

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
                            else if (tile.index === 2)
                                quickSettingsBackend.toggleMute();
                            else
                                Idle.toggleCaffeine();
                        }
                    }
                }
            }
        }

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

                Rectangle {
                    id: volumeTrack

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

        Rectangle {
            id: notifCard
            width: parent.width
            readonly property int listHeight: Math.min(notifColumn.implicitHeight, Layout.s(210))
            height: Notifs.notClosed.length > 0
                ? notifHeader.height + Layout.s(20) + listHeight
                : notifHeader.height + Layout.s(46)
            radius: 22
            color: Theme.surface_container_highest
            visible: Notifs.notClosed.length > 0 || Notifs.dnd

            Item {
                id: notifHeader
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                height: 24

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "notifications"
                        color: Theme.on_surface
                        font {
                            family: "Material Symbols Rounded"
                            pixelSize: 18
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Notifs.notClosed.length > 0 ? Notifs.notClosed.length : "off"
                        color: Theme.on_surface_variant
                        font {
                            family: "Google Sans"
                            pixelSize: 12
                            weight: Font.Medium
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        visible: Notifs.notClosed.length > 0
                        color: dndMouse.containsMouse
                            ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.10)
                            : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: Notifs.dnd ? "notifications_off" : "notifications_active"
                            color: Notifs.dnd ? Theme.primary : Theme.on_surface_variant
                            font {
                                family: "Material Symbols Rounded"
                                pixelSize: 17
                            }
                        }

                        MouseArea {
                            id: dndMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notifs.toggleDnd()
                        }
                    }

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        visible: Notifs.notClosed.length > 0
                        color: clearMouse.containsMouse
                            ? Qt.rgba(Theme.critical.r, Theme.critical.g, Theme.critical.b, 0.18)
                            : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "delete_sweep"
                            color: clearMouse.containsMouse ? Theme.critical : Theme.on_surface_variant
                            font {
                                family: "Material Symbols Rounded"
                                pixelSize: 17
                            }
                        }

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: notifClearTimer.restart()
                        }
                    }
                }
            }

            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 14
                height: 24
                visible: Notifs.notClosed.length === 0

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: Notifs.dnd ? "Do not disturb is on" : "No notifications yet"
                    color: Theme.on_surface_variant
                    font {
                        family: "Google Sans"
                        pixelSize: 12
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Notifs.dnd ? "bell_off" : "bell"
                    color: Theme.primary
                    font {
                        family: "Material Symbols Rounded"
                        pixelSize: 18
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifs.toggleDnd()
                }
            }

            Flickable {
                id: notifFlick
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: notifHeader.bottom
                anchors.topMargin: Layout.s(6)
                height: notifCard.listHeight
                clip: true
                contentWidth: width
                contentHeight: notifColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                visible: Notifs.notClosed.length > 0

                ScrollBar.vertical: ScrollBar {}

                Column {
                    id: notifColumn
                    width: notifFlick.contentWidth
                    spacing: 2

                    Repeater {
                        model: Notifs.notClosed

                        delegate: NotifHistoryRow {
                            required property var modelData
                            required property int index

                            notif: modelData
                            flat: true
                            width: notifColumn.width

                            id: notifRow

                            property bool revealed: false

                            opacity: quickSettingsWindow.shown && notifRow.revealed ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 210
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Timer {
                                id: stagger
                                interval: Math.min(notifRow.index * 24, 420)
                                onTriggered: notifRow.revealed = true
                            }

                            Connections {
                                target: PanelState
                                function onMergedChanged() {
                                    if (!PanelState.merged)
                                        return;
                                    notifRow.revealed = false;
                                    stagger.restart();
                                }
                            }
                        }
                    }
                }
            }
        }

        Timer {
            id: notifClearTimer
            interval: 15
            repeat: true
            onTriggered: {
                const batch = Notifs.notClosed.slice(0, 30);
                if (batch.length === 0) {
                    notifClearTimer.stop();
                    return;
                }
                for (const n of batch)
                    n.close();
            }
        }

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
