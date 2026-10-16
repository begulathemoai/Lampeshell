import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.services
import "../../theme"

PanelWindow {
    id: root

    property var entry: null
    property string monitorName: ""

    readonly property var opener: menuOpener.children
        ? (menuOpener.children.values ? menuOpener.children.values : [])
        : []

    implicitWidth: Layout.s(268)
    implicitHeight: entries.implicitHeight + Layout.s(36)
    color: "transparent"
    visible: false
    exclusiveZone: -1

        screen: monitorName.length > 0
            ? (Quickshell.screens.find(s => s.name === monitorName) ?? Quickshell.screens[0])
            : Quickshell.screens[0]

    anchors {
        top: true
        right: true
    }

    margins {
        top: Layout.topBarHeight
        right: 0
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "lampshell_tray_menu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    HyprlandFocusGrab {
        id: focusGrab

        windows: [root]
        active: root.visible

        onCleared: {
            if (root.visible)
                root.close();
        }
    }

    function publishGeometry() {
        if (!visible)
            return;
        PanelState.setContentSizeFor("tray", root.width + Layout.s(18), root.height);
    }

    function show(handle) {
        entry = handle;

        if (!entry)
            return;

        visible = true;
        if (!PanelState.beginFor("tray", root.monitorName, root.width + Layout.s(18), root.height)) {
            visible = false;
            return;
        }
        reveal.visible = true;
        Qt.callLater(root.publishGeometry);

        Qt.callLater(function() {
            if (entry && entry.updateLayout)
                entry.updateLayout();
        });
    }

    Timer {
        id: hideTimer

        interval: Motion.duration(Motion.defaultSpatial)
        onTriggered: {
            root.visible = false;
        }
    }

    function close() {
        reveal.visible = false;
        hideTimer.restart();
        entry = null;
        PanelState.closeFor("tray");
    }

    onWidthChanged: publishGeometry()
    onHeightChanged: publishGeometry()
    onScreenChanged: publishGeometry()

    Rectangle {
        id: card

        anchors.fill: parent
        radius: 22
        color: Theme.surface_container_lowest

        opacity: reveal.visible ? 1 : 0
        scale: reveal.visible ? 1 : 0.94

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.duration(Motion.defaultSpatial)
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Motion.duration(Motion.defaultSpatial)
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        id: reveal

        anchors.fill: parent
        visible: false
        color: "transparent"
    }

    QsMenuOpener {
        id: menuOpener

        menu: root.entry
    }

    Column {
        id: entries

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 2

        Repeater {
            model: root.opener

            delegate: Rectangle {
                id: row

                required property QsMenuEntry modelData

                width: entries.width
                height: modelData.isSeparator ? 6 : 30
                radius: 9
                color: modelData.isSeparator
                    ? "transparent"
                    : (hover.hovered && modelData.enabled ? Theme.surface_container_high : "transparent")

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 2
                    anchors.bottomMargin: 2
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    visible: row.modelData.isSeparator
                    radius: 1
                    color: Theme.outline_variant
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10
                    visible: !row.modelData.isSeparator

                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        visible: row.modelData.icon !== ""
                        source: row.modelData.icon
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 26
                        text: row.modelData.text
                        color: row.modelData.enabled ? Theme.on_surface : Theme.on_surface_variant
                        elide: Text.ElideRight
                        font {
                            family: "Google Sans"
                            pixelSize: 13
                        }
                    }
                }

                HoverHandler {
                    id: hover

                    enabled: row.modelData.enabled && !row.modelData.isSeparator
                }

                TapHandler {
                    enabled: row.modelData.enabled && !row.modelData.isSeparator
                    onTapped: {
                        row.modelData.triggered();
                        root.close();
                    }
                }
            }
        }
    }
}
