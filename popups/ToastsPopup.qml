import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.theme
import qs.services

Variants {
    id: root
    model: Quickshell.screens

    delegate: PanelWindow {
        id: toastWindow

        required property var modelData
        screen: modelData

        readonly property bool isFocused: Hyprland.focusedMonitor && modelData.name === Hyprland.focusedMonitor.name
        readonly property var cards: isFocused ? Toaster.toasts.filter(t => !t.closed || t.locks.length > 0).slice(0, Toaster.maxVisible) : []

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "toast_overlay"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        color: "transparent"

        anchors { bottom: true; right: true }
        margins { bottom: Layout.bottomBarHeight + Layout.s(30); right: Layout.rightBarWidth + Layout.s(5) }

        visible: toastWindow.surfaceActive
        implicitWidth: toastWindow.surfaceActive ? 390 : 0
        implicitHeight: toastWindow.surfaceActive ? modelData.height : 0

        Timer { id: exitTimer; interval: 350 }
        onCardsChanged: { if (cards.length === 0) exitTimer.restart(); }
        readonly property bool surfaceActive: cards.length > 0 || exitTimer.running

        mask: Region { item: stack }

        Item {
            id: stack
            width: 350
            height: cardColumn.implicitHeight
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.bottomMargin: 20
            anchors.rightMargin: 20

            Column {
                id: cardColumn
                width: 350
                spacing: 8

                Repeater {
                    model: toastWindow.cards

                    delegate: Item {
                        id: toastCard

                        required property var modelData
                        readonly property var toast: modelData

                        width: 350
                        height: inner.height + 16
                        opacity: 0

                        Component.onCompleted: {
                            toastCard.toast.lock(toastCard);
                            if (toastCard.isNew)
                                enterAnim.start();
                            else {
                                toastCard.y = 0;
                                toastCard.opacity = 1;
                            }
                        }
                        Component.onDestruction: toastCard.toast.unlock(toastCard)

                        readonly property bool isNew: true

                        SequentialAnimation {
                            id: enterAnim
                            NumberAnimation {
                                target: toastCard
                                property: "opacity"
                                to: 1
                                duration: 200
                            }
                        }

                        Connections {
                            target: toastCard.toast
                            function onClosedChanged() {
                                if (toastCard.toast.closed)
                                    exitAnim.start();
                            }
                        }

                        SequentialAnimation {
                            id: exitAnim
                            NumberAnimation {
                                target: toastCard
                                property: "opacity"
                                to: 0
                                duration: 250
                            }
                            onFinished: toastCard.toast.unlock(toastCard)
                        }

                        Rectangle {
                            id: inner
                            width: 350
                            height: layout.implicitHeight + 24
                            radius: 24

                            color: {
                                switch (toastCard.toast.type) {
                                case Toaster.success: return Qt.tint(Theme.surface, Qt.rgba(Theme.success?.r ?? 0.2, Theme.success?.g ?? 0.7, Theme.success?.b ?? 0.4, 0.15));
                                case Toaster.warning: return Qt.tint(Theme.surface, Qt.rgba(Theme.secondary?.r ?? 0.8, Theme.secondary?.g ?? 0.7, Theme.secondary?.b ?? 0.2, 0.15));
                                case Toaster.error: return Qt.tint(Theme.surface, Qt.rgba(Theme.critical.r, Theme.critical.g, Theme.critical.b, 0.15));
                                default: return Theme.surface;
                                }
                            }
                            border.color: Theme.outline_variant
                            border.width: 1

                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: Qt.rgba(Theme.shadow.r, Theme.shadow.g, Theme.shadow.b, 0.25)
                                blurMax: 32
                                shadowBlur: 0.85
                                shadowVerticalOffset: 4
                            }

                            Row {
                                id: layout
                                width: parent.width - 32
                                anchors.centerIn: parent
                                spacing: 12

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 36
                                    height: 36
                                    radius: 18
                                    color: {
                                        switch (toastCard.toast.type) {
                                        case Toaster.success: return Theme.success ?? Theme.primary;
                                        case Toaster.warning: return Theme.secondary ?? Theme.primary;
                                        case Toaster.error: return Theme.critical;
                                        default: return Theme.primary;
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: toastCard.toast.icon
                                        color: Theme.on_primary
                                        font { family: Layout.fontIcons; pixelSize: Layout.s(18) }
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 48
                                    spacing: 2

                                    Text {
                                        width: parent.width
                                        text: toastCard.toast.title
                                        color: Theme.on_surface
                                        elide: Text.ElideRight
                                        font { family: Layout.fontSans; pixelSize: Layout.ts(14); weight: Font.Medium }
                                    }

                                    Text {
                                        width: parent.width
                                        text: toastCard.toast.message
                                        color: Theme.on_surface_variant
                                        visible: text.length > 0
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                        font { family: Layout.fontSans; pixelSize: Layout.ts(12) }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: toastCard.toast.close()
                        }
                    }
                }
            }
        }
    }
}