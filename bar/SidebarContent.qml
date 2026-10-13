import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects
import Quickshell.Services.Notifications
import qs.theme
import qs.services


Item {
    id: root

    property bool isFocused: Hyprland.focusedMonitor
        && (Hyprland.focusedMonitor.name === (Layout.targetMonitor ?? ""))
    readonly property real uiScale: Layout.uiScale  // single source of truth

    readonly property real itemSpacing: 10 * uiScale
    readonly property real itemWidth: 56 * uiScale
    readonly property real itemHeight: 56 * uiScale
    readonly property real pillRadius: 28 * uiScale
    readonly property real innerPad: 8 * uiScale

    signal launcherRequested()

    readonly property var _activePlayer: Players.active
    readonly property string mediaTitle: Players.activeTitle
    readonly property string mediaArtist: Players.activeArtist
    readonly property bool hasMedia: mediaTitle.length > 0

    readonly property var notifStack: Notifs.notClosed

    Column {
        anchors.fill: parent
        anchors.topMargin: 4
        spacing: root.itemSpacing

        Rectangle {
            id: launcherPill
            width: root.itemWidth
            height: root.itemWidth
            radius: root.pillRadius
            color: launcherMa.pressed
                ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.10)
                : launcherMa.containsMouse
                    ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)
                    : Theme.surface_container
            anchors.horizontalCenter: parent.horizontalCenter
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowColor: Qt.rgba(Theme.shadow.r, Theme.shadow.g, Theme.shadow.b, 0.25)
                shadowBlur: 0.85
                shadowVerticalOffset: 4
            }
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "apps"
                color: Theme.on_surface
                font { family: "Material Symbols Rounded"; pixelSize: 28 * root.uiScale }
            }

            MouseArea {
                id: launcherMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.launcherRequested()
            }
        }

        Rectangle {
            id: mediaPill
            visible: root.hasMedia
            width: root.itemWidth
            height: root.itemWidth
            radius: root.pillRadius
            color: mediaMa.pressed
                ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.20)
                : mediaMa.containsMouse
                    ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                    : Theme.primary_container
            anchors.horizontalCenter: parent.horizontalCenter
            Behavior on color { ColorAnimation { duration: 150 } }

            Column {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Players.activeIsPlaying ? "pause" : "play_arrow"
                    color: Theme.on_primary_container
                    font { family: "Material Symbols Rounded"; pixelSize: 22 * root.uiScale }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        const m = root.mediaArtist.length > 0
                            ? root.mediaArtist.charAt(0).toUpperCase()
                            : "?";
                        return m;
                    }
                    color: Theme.on_primary_container
                    font { family: "Google Sans"; pixelSize: 11 * root.uiScale; bold: true }
                }
            }
            MouseArea {
                id: mediaMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root._activePlayer) root._activePlayer.togglePlaying();
                }
            }
        }

        Column {
            id: notifArea
            width: root.itemWidth
            spacing: root.itemSpacing
            height: parent.height - launcherPill.height - (mediaPill.visible ? mediaPill.height + root.itemSpacing : 0) - root.itemSpacing
            clip: true

            Repeater {
                model: root.notifStack.slice(0, 8)
                delegate: Rectangle {
                    id: cardItem
                    required property var modelData
                    width: root.itemWidth
                    height: root.itemWidth
                    radius: root.pillRadius
                    color: {
                        if (modelData.urgency === NotificationUrgency.Critical)
                            return Qt.rgba(Theme.critical.r, Theme.critical.g, Theme.critical.b, 0.18);
                        return cardMa.pressed
                            ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.10)
                            : cardMa.containsMouse
                                ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)
                                : Theme.surface_container;
                    }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: {
                            const n = modelData.appName || "?";
                            return n.length > 0 ? n.charAt(0).toUpperCase() : "?";
                        }
                        color: Theme.on_surface
                        font { family: "Google Sans"; pixelSize: 22 * root.uiScale; bold: true }
                    }
                    MouseArea {
                        id: cardMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (cardItem.modelData)
                                cardItem.modelData.close();
                        }
                    }
                }
            }
        }
    }
}
