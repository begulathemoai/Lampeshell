import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import qs.theme
import qs.services
import qs.popups.settings
import qs.popups.nexus.common

PanelWindow {
    id: quickSettingsWindow

    implicitWidth: Layout.s(400) + Layout.s(24)
    implicitHeight: content.implicitHeight + 36 + Layout.s(24)
    color: "transparent"
    visible: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quick_settings_overlay"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: -1

    anchors {
        top: Layout.barAtTop
        bottom: Layout.barAtBottom || Layout.barVertical
        left: Layout.barAtLeft
        right: Layout.barAtRight || Layout.barHorizontal
    }

    margins {
        top: Layout.barAtTop ? Layout.topBarHeight : 0
        bottom: Layout.barAtBottom || Layout.barVertical ? Layout.bottomBarHeight : 0
        left: Layout.barAtLeft ? Layout.sideBarWidth : 0
        right: Layout.barAtRight || Layout.barHorizontal ? Layout.rightBarWidth : 0
    }

    function screenForFocus() {
        const active = Hyprland.focusedMonitor ?? null;
        return active && active.name ? Quickshell.screens.find(s => s.name === active.name) ?? Quickshell.screens[0] : Quickshell.screens[0];
    }
    property var targetScreen: screenForFocus()
    screen: targetScreen

    function open() {
        quickSettingsBackend.refreshBrightness();
        quickSettingsWindow.targetScreen = quickSettingsWindow.screenForFocus();
        const token = PanelState.beginFor(quickSettingsWindow);
        if (!token) {
            quickSettingsWindow.visible = false;
            return;
        }
        quickSettingsWindow.panelGeneration = token;
        quickSettingsWindow.shown = true;
        quickSettingsWindow.visible = true;
        Qt.callLater(function() {
            focusGrab.active = true;
            panelSurface.forceActiveFocus();
        });
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
        if (!quickSettingsWindow.shown && !quickSettingsWindow.visible)
            return;
        quickSettingsWindow.shown = false;
        PanelState.closeFor(quickSettingsWindow, quickSettingsWindow.panelGeneration);
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
    property int panelGeneration: 0

    Timer {
        id: hideWhenDone
        interval: Motion.duration(Motion.defaultSpatial) + 50
        onTriggered: {
            if (!quickSettingsWindow.shown)
                quickSettingsWindow.visible = false;
        }
    }

    Connections {
        target: PanelState
        function onAcquired(acquiredOwner, acquiredGeneration) {
            if (acquiredOwner !== quickSettingsWindow)
                return;
            quickSettingsWindow.panelGeneration = acquiredGeneration;
            quickSettingsWindow.shown = true;
            quickSettingsWindow.visible = true;
            focusGrab.active = true;
            panelSurface.forceActiveFocus();
        }
        function onReleased(releasedOwner, releasedGeneration) {
            if (releasedOwner === quickSettingsWindow
                    && releasedGeneration === quickSettingsWindow.panelGeneration) {
                quickSettingsWindow.visible = false;
                quickSettingsWindow.shown = false;
            }
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

    property bool pointerHeld: false
    property bool closePending: false

    function releasePointer() {
        quickSettingsWindow.pointerHeld = false;
        if (quickSettingsWindow.closePending) {
            quickSettingsWindow.closePending = false;
            quickSettingsWindow.close();
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [quickSettingsWindow]
        onCleared: {
            if (quickSettingsWindow.pointerHeld) {
                quickSettingsWindow.closePending = true;
                return;
            }
            quickSettingsWindow.close();
        }
    }

    mask: Region {
        item: surface
    }

    Item {
        id: panelSurface
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: function(event) {
            quickSettingsWindow.close();
            event.accepted = true;
        }
    }

    PanelSurface {
        id: surface

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.topMargin: Layout.barAtTop || Layout.barVertical ? 0 : Layout.s(24)
        anchors.rightMargin: Layout.barAtRight || Layout.barHorizontal ? 0 : Layout.s(24)
        anchors.leftMargin: Layout.barAtLeft ? 0 : Layout.s(24)
        anchors.bottomMargin: Layout.barAtBottom ? 0 : Layout.s(24)

        // Flush edges stay square; the corner that lands on the bezel's rounded
        // cutout corner takes the bezel radius so the panel nests into the frame.
        topLeftRadius: Layout.barAtBottom ? Layout.panelRadius
            : Layout.barAtLeft ? Layout.cornerRadius
            : 0
        topRightRadius: Layout.barAtBottom ? Layout.panelRadius
            : Layout.barAtLeft ? 0
            : Layout.cornerRadius
        bottomLeftRadius: Layout.barAtLeft || Layout.barAtBottom ? 0 : Layout.panelRadius
        bottomRightRadius: Layout.barAtTop || Layout.barAtLeft ? Layout.panelRadius
            : Layout.barAtRight ? 0
            : Layout.cornerRadius

        opacity: quickSettingsWindow.shown ? 1 : 0
        x: quickSettingsWindow.shown ? 0
            : (Layout.barAtLeft ? -Layout.s(16) : Layout.barAtRight ? Layout.s(16) : 0)
        y: quickSettingsWindow.shown ? 0
            : (Layout.barAtTop ? -Layout.s(16) : Layout.barAtBottom ? Layout.s(16) : 0)

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.duration(Motion.defaultSpatial)
                easing.type: Easing.OutCubic
            }
        }

        Behavior on x {
            NumberAnimation {
                duration: Motion.duration(Motion.defaultSpatial)
                easing.type: Easing.OutCubic
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: Motion.duration(Motion.defaultSpatial)
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            id: backdrop
            anchors.fill: parent
            onPressed: quickSettingsWindow.pointerHeld = true
            onReleased: {
                quickSettingsWindow.releasePointer();
                quickSettingsWindow.close();
            }
            onCanceled: quickSettingsWindow.releasePointer()
        }

        Column {
            id: content
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

        Rectangle {
            id: notifCard
            width: parent.width
            readonly property int listHeight: Math.min(notifColumn.implicitHeight, Layout.s(210))
            readonly property int bodyHeight: Notifs.history.length > 0
                ? Math.max(listHeight, Layout.s(88))
                : Layout.s(88)
            implicitHeight: 14 + notifHeader.height + Layout.s(16) + bodyHeight + 14
            radius: 22
            color: Theme.surface_container_low

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
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Notifs.notClosed.length > 0
                        text: Notifs.notClosed.length
                        color: Theme.outline
                        font {
                            family: "Google Sans"
                            pixelSize: 12
                            weight: Font.Medium
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Notifications"
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
                id: emptyState
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: notifHeader.bottom
                anchors.topMargin: Layout.s(16)
                height: Layout.s(88)
                        visible: Notifs.history.length === 0

                Column {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Notifs.dnd ? "notifications_off" : "notifications_none"
                        color: Theme.outline_variant
                        font {
                            family: "Material Symbols Rounded"
                            pixelSize: 30
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Notifs.dnd ? "Do not disturb is on" : "All up to date!"
                        color: Theme.on_surface_variant
                        font {
                            family: "Google Sans"
                            pixelSize: 13
                            weight: Font.Medium
                        }
                    }
                }
            }

            Flickable {
                id: notifFlick
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: notifHeader.bottom
                anchors.topMargin: Layout.s(16)
                height: notifCard.listHeight
                clip: true
                contentWidth: width
                contentHeight: notifColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                visible: Notifs.history.length > 0

                ScrollBar.vertical: ThemedScrollBar {}

                Column {
                    id: notifColumn
                    width: notifFlick.contentWidth
                    spacing: 2

                    Repeater {
                        model: Notifs.history

                        delegate: NotifHistoryRow {
                            required property var modelData
                            required property int index

                            notif: modelData
                            flat: true
                            width: notifColumn.width

                            id: notifRow

                            property bool revealed: false
                            property bool leaving: false
                            property real exitFactor: 1
                            property real exitOffset: 0

                            x: exitOffset
                            height: implicitHeight
                            opacity: notifRow.revealed ? exitFactor : 0
                            clip: true

                            function startExit() {
                                if (notifRow.leaving)
                                    return;
                                stagger.stop();
                                notifRow.revealed = true;
                                exitAnimation.start();
                            }

                            Component.onCompleted: {
                                modelData.lock(notifRow);
                                if (modelData.closed)
                                    Qt.callLater(notifRow.startExit);
                            }

                            Component.onDestruction: modelData.unlock(notifRow)

                            Connections {
                                target: modelData

                                function onClosedChanged() {
                                    if (modelData.closed)
                                        notifRow.startExit();
                                }
                            }

                            ParallelAnimation {
                                id: exitAnimation

                                NumberAnimation {
                                    target: notifRow
                                    property: "exitFactor"
                                    to: 0
                                    duration: Motion.duration(Motion.standard)
                                    easing.type: Easing.OutCubic
                                }
                                NumberAnimation {
                                    target: notifRow
                                    property: "exitOffset"
                                    to: Layout.s(18)
                                    duration: Motion.duration(Motion.standard)
                                    easing.type: Easing.OutCubic
                                }

                                onStarted: notifRow.leaving = true
                                onFinished: modelData.unlock(notifRow)
                            }

                            Timer {
                                id: stagger
                                interval: Math.min(notifRow.index * 24, 420)
                                onTriggered: {
                                    if (!notifRow.leaving)
                                        notifRow.revealed = true;
                                }
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

        Rectangle {
            id: keepAwakeCard
            width: parent.width
            implicitHeight: keepAwakeCol.implicitHeight + 28
            radius: 22
            color: Theme.surface_container

            Column {
                id: keepAwakeCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 12

                Row {
                    width: parent.width
                    spacing: 14

                    Rectangle {
                        width: 44
                        height: 44
                        radius: 22
                        color: Idle.caffeine ? Theme.secondary : Theme.secondary_container

                        Behavior on color {
                            ColorAnimation {
                                duration: 160
                                easing.type: Easing.OutCubic
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "coffee"
                            color: Idle.caffeine ? Theme.on_secondary : Theme.on_secondary_container
                            font {
                                family: "Material Symbols Rounded"
                                pixelSize: 22
                            }
                        }
                    }

                    Column {
                        width: parent.width - 44 - keepAwakeSwitch.width - parent.spacing * 2
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: "Keep awake"
                            color: Theme.on_surface
                            font {
                                family: "Google Sans"
                                pixelSize: 13
                                weight: Font.Medium
                            }
                        }

                        Text {
                            width: parent.width
                            text: Idle.caffeine ? "Preventing sleep mode" : "Normal power management"
                            color: Theme.on_surface_variant
                            elide: Text.ElideRight
                            font {
                                family: "Google Sans"
                                pixelSize: 11
                            }
                        }
                    }

                    Switch {
                        id: keepAwakeSwitch
                        anchors.verticalCenter: parent.verticalCenter
                        checked: Idle.caffeine
                        onToggled: next => Idle.setCaffeine(next)
                    }
                }

                Rectangle {
                    visible: Idle.caffeine
                    implicitWidth: activeSinceText.width + 24
                    implicitHeight: 26
                    radius: 13
                    color: Theme.primary

                    Text {
                        id: activeSinceText
                        anchors.centerIn: parent
                        text: "Active since " + Idle.activeSince
                        color: Theme.on_primary
                        font {
                            family: "Google Sans"
                            pixelSize: 11
                            weight: Font.Medium
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            implicitHeight: sliderCol.implicitHeight + 32
            radius: 22
            color: Theme.surface_container

            Column {
                id: sliderCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 16
                spacing: 16

                FilledSlider {
                    width: parent.width
                    icon: quickSettingsBackend.isMuted ? "volume_off"
                        : (quickSettingsBackend.volumeLevel >= 0.5 ? "volume_up" : "volume_down")
                    value: quickSettingsBackend.volumeLevel
                    onMoved: value => quickSettingsBackend.setVolume(value)
                }

                FilledSlider {
                    width: parent.width
                    icon: quickSettingsBackend.brightnessLevel >= 0.7 ? "brightness_high"
                        : (quickSettingsBackend.brightnessLevel >= 0.3 ? "brightness_medium" : "brightness_low")
                    value: quickSettingsBackend.brightnessLevel
                    onMoved: value => quickSettingsBackend.setBrightness(value)
                }
            }
        }

        Rectangle {
            id: controlsCard
            width: parent.width
            implicitHeight: controlsCol.implicitHeight + 28
            radius: 22
            color: Theme.surface_container

            Column {
                id: controlsCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 12

                Text {
                    text: "Quick toggles"
                    color: Theme.on_surface
                    font {
                        family: "Google Sans"
                        pixelSize: 13
                        weight: Font.Medium
                    }
                }

                Row {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: 6

                        delegate: Item {
                            id: toggle
                            required property int index
                            width: (controlsCol.width - 5 * 8) / 6
                            height: width

                            readonly property bool toggleOn: {
                                if (index === 0)
                                    return quickSettingsBackend.wifiEnabled;
                                if (index === 1)
                                    return quickSettingsBackend.btPowered;
                                if (index === 2)
                                    return !quickSettingsBackend.isMutedSource;
                                if (index === 3)
                                    return GameMode.enabled;
                                if (index === 4)
                                    return Notifs.dnd;
                                return false;
                            }

                            readonly property string iconName: {
                                if (index === 0)
                                    return quickSettingsBackend.wifiEnabled ? "wifi" : "wifi_off";
                                if (index === 1)
                                    return quickSettingsBackend.btPowered ? "bluetooth" : "bluetooth_disabled";
                                if (index === 2)
                                    return quickSettingsBackend.isMutedSource ? "mic_off" : "mic";
                                if (index === 3)
                                    return "sports_esports";
                                if (index === 4)
                                    return Notifs.dnd ? "notifications_off" : "notifications";
                                return "settings";
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: Layout.s(16)

                                color: toggle.toggleOn
                                    ? Theme.primary
                                    : (toggleMouse.containsMouse
                                        ? Qt.tint(Theme.surface_container_high, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08))
                                        : Theme.surface_container_high)

                                scale: toggleMouse.pressed ? 0.92 : 1.0

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

                            Text {
                                anchors.centerIn: parent
                                text: toggle.iconName
                                color: toggle.toggleOn ? Theme.on_primary : Theme.on_surface_variant
                                font {
                                    family: "Material Symbols Rounded"
                                    pixelSize: 20
                                }
                            }

                            MouseArea {
                                id: toggleMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (toggle.index === 0)
                                        quickSettingsBackend.toggleWifi();
                                    else if (toggle.index === 1)
                                        quickSettingsBackend.toggleBluetooth();
                                    else if (toggle.index === 2)
                                        quickSettingsBackend.toggleMuteSource();
                                    else if (toggle.index === 3)
                                        GameMode.toggle();
                                    else if (toggle.index === 4)
                                        Notifs.toggleDnd();
                                    else
                                        quickSettingsWindow.openSettings();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    }
}
