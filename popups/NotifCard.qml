import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Notifications
import qs.theme
import qs.utilities

Item {
    id: card

    required property var notif
    required property var window

    readonly property real cardWidth: 350
    readonly property bool isCritical: notif.urgency === NotificationUrgency.Critical
    readonly property bool isLow: notif.urgency === NotificationUrgency.Low
    readonly property bool live: notif.notification !== null && notif.notification !== undefined

    readonly property string appIconUrl: {
        const icon = notif.appIcon;
        if (!icon)
            return "";
        if (icon.startsWith("/") || icon.startsWith("file://") || icon.startsWith("http"))
            return icon;
        return Quickshell.iconPath(icon, true) || "";
    }

    readonly property string displayImage: {
        const img = notif.image;
        if (!img)
            return "";
        if (img.startsWith("image://qsimage/"))
            return "";
        if (img.startsWith("/"))
            return "file://" + img;
        if (img.startsWith("file://"))
            return img;
        return "";
    }
    readonly property bool hasImage: displayImage !== ""

    width: cardWidth
    height: cardInner.height + 20

    x: cardWidth
    opacity: 0
    Behavior on opacity { NumberAnimation { duration: 250 } }

    readonly property bool isFresh: Date.now() - notif.timeMs < 1500
    Component.onCompleted: {
        card.notif.lock(card);
        card.notif.popupLease = true;
        if (card.notif.exiting) {
            card.x = cardWidth;
            card.opacity = 0;
            card.notif.popupLease = false;
            card.notif.unlock(card);
        } else if (card.isFresh) {
            slideIn.start();
        } else {
            card.x = 0;
            card.opacity = 1;
        }
    }

    ParallelAnimation {
        id: slideIn
        NumberAnimation {
            target: card
            property: "x"
            to: 0
            duration: 320
            easing.type: Easing.OutBack
            easing.overshoot: 1.05
        }
        NumberAnimation {
            target: card
            property: "opacity"
            to: 1
            duration: 250
        }
    }

    ParallelAnimation {
        id: slideOut
        running: false
        NumberAnimation {
            target: card
            property: "x"
            to: cardWidth
            duration: 280
            easing.type: Easing.InBack
            easing.overshoot: 1.1
        }
        NumberAnimation {
            target: card
            property: "opacity"
            to: 0
            duration: 220
        }
        onFinished: {
            if (!card.notif)
                return;
            card.notif.unlock(card);
            card.notif.popupLease = false;
            card.notif.endExit();
        }
    }

    function startExit() {
        if (slideOut.running || !card.notif)
            return;
        if (card.opacity === 0)
            return;
        slideOut.start();
    }

    function dismiss() {
        if (!card.notif || card.notif.closed)
            return;
        card.notif.close();
    }

    Component.onDestruction: {
        card.notif.popupLease = false;
        card.notif.unlock(card);
    }

    Connections {
        target: card.notif
        function onClosedChanged() {
            if (card.notif.closed)
                card.startExit();
        }
        function onPopupChanged() {
            if (!card.notif.popup)
                card.startExit();
        }
    }

    Rectangle {
        id: cardInner
        width: card.cardWidth
        height: layout.implicitHeight + 36
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 4

        radius: 28
        color: card.isCritical ? Qt.tint(Theme.surface, Qt.rgba(Theme.critical.r, Theme.critical.g, Theme.critical.b, 0.18))
                              : Theme.surface
        border.color: Theme.outline_variant ?? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.15)
        border.width: 1
        opacity: card.isLow ? 0.7 : 1.0

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(Theme.shadow.r, Theme.shadow.g, Theme.shadow.b, 0.25)
            blurMax: 32
            shadowBlur: 0.85
            shadowVerticalOffset: 4
        }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onEntered: card.notif.pauseExpire()
            onExited: card.notif.resumeExpire()
        }

        Column {
            id: layout
            width: card.cardWidth - 40
            anchors.centerIn: parent
            spacing: 6

            Row {
                width: parent.width
                height: 28
                spacing: 10

                Item {
                    width: 24; height: 24
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Theme.primary_container
                        visible: card.appIconUrl === ""
                        Text {
                            anchors.centerIn: parent
                            text: "!"
                            color: Theme.on_primary_container
                            font { family: "Google Sans"; pixelSize: 13; bold: true }
                        }
                    }
                    Image {
                        anchors.fill: parent
                        source: card.appIconUrl
                        fillMode: Image.PreserveAspectCrop
                        visible: card.appIconUrl !== "" && status === Image.Ready
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: mask
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                        }
                    }
                    Rectangle {
                        id: mask
                        anchors.fill: parent
                        radius: width / 2
                        color: "black"
                        visible: false
                        layer.enabled: true
                    }
                }

                Text {
                    text: card.notif.appName || "Notification"
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                    font { family: "Google Sans"; pixelSize: 14; weight: Font.Medium }
                    elide: Text.ElideRight
                    width: card.cardWidth - 40 - 24 - 10 - 10 - 32
                }

                Item {
                    width: 32; height: 32
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: 16
                        color: closeMa.containsMouse
                            ? Qt.rgba(Theme.critical.r, Theme.critical.g, Theme.critical.b, 0.14)
                            : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "\u00D7"
                        color: closeMa.containsMouse ? Theme.critical : Theme.on_surface_variant
                        font { family: "Google Sans"; pixelSize: 18; weight: Font.Medium }
                    }
                    MouseArea {
                        id: closeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.dismiss()
                    }
                }
            }

            Text {
                width: parent.width
                text: card.notif.summary
                color: Theme.on_surface
                font { family: "Google Sans"; pixelSize: 15; bold: true }
                elide: Text.ElideRight
                visible: card.notif.summary.length > 0
            }

            Image {
                width: parent.width
                height: 120
                visible: card.hasImage && status === Image.Ready
                source: card.displayImage
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(350, 120)
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: imageMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                }

                Rectangle {
                    id: imageMask
                    width: parent.width
                    height: 120
                    radius: 12
                    color: "black"
                    visible: false
                    layer.enabled: true
                }
            }

            Text {
                width: parent.width
                text: Markup.sanitize(card.notif.body)
                textFormat: Text.RichText
                linkColor: Theme.primary
                color: Theme.on_surface_variant
                font { family: "Google Sans"; pixelSize: 13 }
                wrapMode: Text.WordWrap
                maximumLineCount: 4
                elide: Text.ElideRight
                visible: card.notif.body.length > 0
            }

            Row {
                id: actionsRow
                width: parent.width
                spacing: 8
                layoutDirection: Qt.RightToLeft
                readonly property var shown: card.live
                    ? (card.notif.actions || []).filter(a => a.identifier !== "default")
                    : []
                visible: shown.length > 0

                Repeater {
                    model: actionsRow.shown
                    delegate: Rectangle {
                        required property var modelData
                        radius: 14
                        color: actionMa.containsMouse
                            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.14)
                            : "transparent"
                        border.color: Theme.outline_variant
                        border.width: 1
                        implicitWidth: actionText.implicitWidth + 24
                        implicitHeight: 28
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            id: actionText
                            anchors.centerIn: parent
                            text: modelData.text
                            color: Theme.on_surface
                            font { family: "Google Sans"; pixelSize: 12; weight: Font.Medium }
                        }
                        MouseArea {
                            id: actionMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                card.notif.pauseExpire();
                                if (typeof modelData.invoke === "function")
                                    modelData.invoke();
                                card.dismiss();
                            }
                        }
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (card.live) {
                    const acts = (card.notif.actions || []).filter(a => a.identifier === "default");
                    if (acts.length > 0 && typeof acts[0].invoke === "function")
                        acts[0].invoke();
                }
                card.dismiss();
            }
            z: -1
        }
    }
}
