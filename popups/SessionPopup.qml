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
 * Session / power menu.
 *
 * Caelestia exposed these as a single keybound overlay; here it is an
 * overlay-layer panel sharing the quick settings and settings chrome, bound to
 * CTRL+ALT+Delete via vars.kbSession.
 *
 * Destructive rows use a two-press confirm: the first press arms the row and
 * shows a countdown, the second runs it. wlogout is not installed on this
 * system, so the menu is built in-shell rather than delegating to it.
 */
PanelWindow {
    id: sessionWindow

    implicitWidth: 320
    implicitHeight: sessionContent.implicitHeight + 36
    color: "transparent"
    visible: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "session_overlay"
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

    property var targetScreen: {
        const active = Hyprland.focusedMonitor ?? null;
        return active && active.name ? Quickshell.screens.find(s => s.name === active.name) : Quickshell.screens[0];
    }
    screen: targetScreen

    // See Settings.qml: a focus grab can lose the race with surface mapping and
    // clear immediately, which must not be read as the user clicking away.
    property double openedAt: 0
    property int grabRetries: 0

    function open() {
        sessionBackend.cancel();
        sessionWindow.openedAt = Date.now();
        sessionWindow.grabRetries = 0;
        sessionWindow.visible = true;
        Qt.callLater(function() {
            sessionFocusGrab.active = true;
            sessionPanelBg.forceActiveFocus();
        });
    }

    function close() {
        sessionBackend.cancel();
        sessionWindow.visible = false;
    }

    function toggle() {
        if (sessionWindow.visible)
            close();
        else
            open();
    }

    SessionBackend {
        id: sessionBackend
    }

    IpcHandler {
        target: "session"

        function toggle() {
            sessionWindow.toggle();
        }

        function open() {
            sessionWindow.open();
        }

        function close() {
            sessionWindow.close();
        }
    }

    HyprlandFocusGrab {
        id: sessionFocusGrab
        windows: [sessionWindow]
        onCleared: {
            if (Date.now() - sessionWindow.openedAt < 400 && sessionWindow.grabRetries < 3) {
                sessionWindow.grabRetries++;
                Qt.callLater(function() { sessionFocusGrab.active = true; });
                return;
            }
            sessionWindow.close();
        }
    }

    // Only covers this window's own bounds; real click-away is handled by the
    // focus grab above.
    MouseArea {
        anchors.fill: parent
        onClicked: sessionWindow.close()
    }

    Rectangle {
        id: sessionPanelBg
        anchors.centerIn: sessionContent
        width: sessionContent.width + 36
        height: sessionContent.height + 36
        radius: Layout.cornerRadius
        color: Theme.surface_container_low
        border.width: 1
        border.color: Theme.outline_variant
        focus: true

        Keys.onEscapePressed: function(event) {
            sessionWindow.close();
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

    MouseArea {
        anchors.fill: sessionPanelBg
    }

    Column {
        id: sessionContent
        anchors.centerIn: parent
        width: parent.width - 72
        spacing: 8

        Text {
            text: "Session"
            color: Theme.on_surface
            font {
                family: "Google Sans"
                pixelSize: 15
                weight: Font.Medium
            }
        }

        Repeater {
            model: sessionBackend.actions

            delegate: Item {
                id: sessionRow
                required property int index
                required property var modelData

                readonly property bool armed: sessionBackend.isArmed(modelData.id)
                readonly property color rowColor: modelData.destructive && armed
                    ? Qt.rgba(Theme.critical.r, Theme.critical.g, Theme.critical.b, 0.16)
                    : rowMouse.containsMouse
                        ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)
                        : "transparent"

                width: sessionContent.width
                height: 48

                Rectangle {
                    anchors.fill: parent
                    radius: 16
                    color: parent.rowColor

                    Behavior on color {
                        ColorAnimation {
                            duration: 110
                        }
                    }
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 14

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: sessionRow.modelData.icon
                        color: sessionRow.modelData.destructive && sessionRow.armed
                            ? Theme.on_critical
                            : Theme.on_surface_variant
                        font {
                            family: "Material Symbols Rounded"
                            pixelSize: 21
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            text: sessionRow.modelData.label
                            color: Theme.on_surface
                            font {
                                family: "Google Sans"
                                pixelSize: 13
                                weight: Font.Medium
                            }
                        }

                        // Armed state explains itself instead of relying on the
                        // user remembering they pressed something.
                        Text {
                            visible: sessionRow.armed
                            text: "Press again to confirm"
                            color: Theme.on_critical
                            font {
                                family: "Google Sans"
                                pixelSize: 11
                            }
                        }
                    }
                }

                // Armed rows show a progress sweep over the 4s window, so the
                // confirm affordance is visible rather than implicit.
                Rectangle {
                    anchors {
                        left: parent.left
                        bottom: parent.bottom
                        leftMargin: 10
                    }
                    height: 2
                    radius: 1
                    color: Theme.on_critical
                    visible: sessionRow.armed
                    width: 0

                    SequentialAnimation on width {
                        running: sessionRow.armed
                        loops: 1
                        NumberAnimation {
                            from: 0
                            to: sessionRow.width - 20
                            duration: sessionBackend.confirmWindowMs
                            easing.type: Easing.Linear
                        }
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sessionBackend.request(sessionRow.modelData.id)
                }
            }
        }

        Text {
            width: parent.width
            text: "Destructive actions need a second press."
            color: Theme.on_surface_variant
            font {
                family: "Google Sans"
                pixelSize: 11
            }
        }
    }
}