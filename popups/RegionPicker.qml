import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.theme
import qs.services

Variants {
    id: root
    model: Quickshell.screens

    delegate: PanelWindow {
        id: picker

        required property var modelData
        screen: modelData

        readonly property bool isMine: RegionPick.monitor.length === 0
            || RegionPick.monitor === modelData.name

        readonly property real pxScale: {
            const shot = shotImage;
            if (shot.sourceSize.width <= 0 || picker.width <= 0)
                return 1;
            return shot.sourceSize.width / picker.width;
        }

        property real selX: 0
        property real selY: 0
        property real selW: 0
        property real selH: 0
        property point anchorPoint: Qt.point(0, 0)

        readonly property real selRight: selX + selW
        readonly property real selBottom: selY + selH

        function beginDrag(point) {
            picker.anchorPoint = point;
            picker.selX = point.x;
            picker.selY = point.y;
            picker.selW = 0;
            picker.selH = 0;
        }

        function updateDrag(point) {
            picker.selX = Math.min(picker.anchorPoint.x, point.x);
            picker.selY = Math.min(picker.anchorPoint.y, point.y);
            picker.selW = Math.abs(point.x - picker.anchorPoint.x);
            picker.selH = Math.abs(point.y - picker.anchorPoint.y);
        }

        function finishDrag() {
            if (picker.selW < 12 || picker.selH < 12)
                return;
            RegionPick.accept(
                Math.round(picker.selX * picker.pxScale),
                Math.round(picker.selY * picker.pxScale),
                Math.round(picker.selW * picker.pxScale),
                Math.round(picker.selH * picker.pxScale)
            );
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "region_picker"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        color: "transparent"

        anchors { top: true; bottom: true; left: true; right: true }

        visible: RegionPick.open && picker.isMine

        onVisibleChanged: {
            if (!visible)
                return;
            picker.selX = 0;
            picker.selY = 0;
            picker.selW = 0;
            picker.selH = 0;
            Qt.callLater(function() { surface.forceActiveFocus(); });
        }

        Image {
            id: shotImage
            anchors.fill: parent
            source: RegionPick.image.length > 0 ? "file://" + RegionPick.image : ""
            fillMode: Image.PreserveAspectFit
            cache: true
            asynchronous: true
            smooth: true
        }

        Item {
            id: surface
            anchors.fill: parent
            focus: true

            Rectangle {
                x: 0; y: 0
                width: surface.width
                height: Math.max(0, picker.selY)
                color: Theme.scrim
                opacity: 0.55
            }
            Rectangle {
                x: 0; y: picker.selBottom
                width: surface.width
                height: Math.max(0, surface.height - picker.selBottom)
                color: Theme.scrim
                opacity: 0.55
            }
            Rectangle {
                x: 0; y: picker.selY
                width: Math.max(0, picker.selX)
                height: picker.selH
                color: Theme.scrim
                opacity: 0.55
            }
            Rectangle {
                x: picker.selRight; y: picker.selY
                width: Math.max(0, surface.width - picker.selRight)
                height: picker.selH
                color: Theme.scrim
                opacity: 0.55
            }

            Rectangle {
                x: picker.selX
                y: picker.selY
                width: picker.selW
                height: picker.selH
                visible: picker.selW > 0 && picker.selH > 0
                color: "transparent"
                border.color: Theme.primary
                border.width: 2

                Rectangle {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: 2
                    width: sizeText.implicitWidth + 16
                    height: 26
                    radius: 8
                    color: Theme.primary

                    Text {
                        id: sizeText
                        anchors.centerIn: parent
                        text: Math.round(picker.selW * picker.pxScale) + " x " + Math.round(picker.selH * picker.pxScale)
                        color: Theme.on_primary
                        font {
                            family: "Google Sans"
                            pixelSize: 13
                            weight: Font.Medium
                        }
                    }
                }
            }

            Rectangle {
                anchors.centerIn: parent
                visible: picker.selW <= 0 && picker.selH <= 0
                width: hintRow.implicitWidth + 32
                height: 44
                radius: 22
                color: Qt.rgba(0, 0, 0, 0.62)

                Row {
                    id: hintRow
                    anchors.centerIn: parent
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Drag to select"
                        color: "white"
                        font {
                            family: "Google Sans"
                            pixelSize: 14
                            weight: Font.Medium
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Esc to cancel"
                        color: Qt.rgba(1, 1, 1, 0.65)
                        font {
                            family: "Google Sans"
                            pixelSize: 13
                        }
                    }
                }
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                onPressed: function(event) { picker.beginDrag(Qt.point(event.x, event.y)); }
                onPositionChanged: function(event) {
                    if (pressed)
                        picker.updateDrag(Qt.point(event.x, event.y));
                }
                onReleased: picker.finishDrag()
            }

            Keys.onEscapePressed: function(event) {
                RegionPick.cancel();
                event.accepted = true;
            }
        }

        HyprlandFocusGrab {
            id: grab
            windows: [picker]
            onCleared: RegionPick.cancel()
        }
        Component.onCompleted: grab.active = RegionPick.open
        Connections {
            target: RegionPick
            function onOpenChanged() {
                grab.active = RegionPick.open;
            }
        }
    }
}