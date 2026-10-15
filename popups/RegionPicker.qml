import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
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

        readonly property bool picking: RegionPick.open && picker.isMine

        readonly property real pxScale: screen.scale > 0 ? screen.scale : 1

        property real anchorX: 0
        property real anchorY: 0
        property real sx: 0
        property real sy: 0
        property real ex: 0
        property real ey: 0
        property bool dragging: false
        property bool onClient: false
        property bool releaseCaptureActive: false
        property bool aiming: false
        property bool captured: false

        readonly property real rsx: Math.min(sx, ex)
        readonly property real rsy: Math.min(sy, ey)
        readonly property real sw: Math.abs(sx - ex)
        readonly property real sh: Math.abs(sy - ey)

        readonly property string shotPath: "/tmp/lampshell-picker-"
            + Quickshell.processId + "-" + Date.now() + ".png"

        readonly property var clients: {
            const mon = Hyprland.monitorFor(screen);
            if (!mon)
                return [];
            const aw = mon.activeWorkspace;
            if (!aw)
                return [];
            const values = aw.toplevels ? aw.toplevels.values : [];
            const result = [];
            for (const t of values) {
                const ipc = t.lastIpcObject;
                if (!ipc || !ipc.at || !ipc.size)
                    continue;
                result.push({
                    x: ipc.at[0] - screen.x,
                    y: ipc.at[1] - screen.y,
                    w: ipc.size[0],
                    h: ipc.size[1]
                });
            }
            return result;
        }

        function snapTo(x, y) {
            for (const c of picker.clients) {
                if (x >= c.x && y >= c.y && x <= c.x + c.w && y <= c.y + c.h) {
                    picker.onClient = true;
                    picker.sx = c.x;
                    picker.sy = c.y;
                    picker.ex = c.x + c.w;
                    picker.ey = c.y + c.h;
                    return;
                }
            }
            picker.onClient = false;
        }

        function resetSelection() {
            const w = picker.width;
            const h = picker.height;
            if (w <= 0 || h <= 0)
                return;
            picker.sx = w / 2 - 100;
            picker.sy = h / 2 - 100;
            picker.ex = w / 2 + 100;
            picker.ey = h / 2 + 100;
        }

        function beginCapture() {
            picker.aiming = false;
            captureDelay.restart();
        }

        function captureNow() {
            if (RegionPick.freeze)
                frozenLoader.active = true;
            else
                liveLoader.active = true;
        }

        function save() {
            const rx = Math.ceil(picker.rsx);
            const ry = Math.ceil(picker.rsy);
            const rw = Math.floor(picker.sw);
            const rh = Math.floor(picker.sh);

            if (!(rw > 0 && rh > 0)) {
                RegionPick.finish(null);
                return;
            }

            if (RegionPick.image.length > 0) {
                const scale = picker.pxScale > 0 ? picker.pxScale : 1;
                RegionPick.finish({
                    path: RegionPick.image,
                    out: RegionPick.outPath,
                    x: Math.round(rx * scale),
                    y: Math.round(ry * scale),
                    w: Math.round(rw * scale),
                    h: Math.round(rh * scale)
                });
                return;
            }

            const target = RegionPick.freeze ? frozenLoader.item : liveLoader.item;
            if (!target) {
                RegionPick.finish(null);
                return;
            }

            target.grabToImage(function(result) {
                if (!result) {
                    RegionPick.finish(null);
                    return;
                }

                const scale = picker.pxScale > 0 ? picker.pxScale : 1;

                result.saveToFile("file://" + picker.shotPath);
                RegionPick.finish({
                    path: picker.shotPath,
                    out: RegionPick.outPath,
                    x: Math.round(rx * scale),
                    y: Math.round(ry * scale),
                    w: Math.round(rw * scale),
                    h: Math.round(rh * scale)
                });
            });
        }

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "region_picker"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: picker.picking ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"

        anchors { top: true; bottom: true; left: true; right: true }

        visible: picker.picking

        onPickingChanged: {
            if (!RegionPick.open)
                return;
            picker.onClient = false;
            picker.dragging = false;
            picker.releaseCaptureActive = false;
            liveLoader.active = false;
            frozenLoader.active = false;
            picker.aiming = true;
            picker.resetSelection();

            if (RegionPick.freeze) {
                frozenLoader.active = true;
            }

            Qt.callLater(function() {
                surface.forceActiveFocus();
                cursorProc.running = true;
            });
        }

        onVisibleChanged: {
            if (!visible) {
            }
        }

        Process {
            id: cursorProc
            command: ["hyprctl", "cursorpos", "-j"]

            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        const pos = JSON.parse(text);
                        picker.snapTo(pos.x, pos.y);
                    } catch (e) {
                        picker.onClient = false;
                    }
                }
            }
        }

        Loader {
            id: frozenLoader
            anchors.fill: parent
            active: false
            asynchronous: true
            visible: RegionPick.freeze && picker.picking

            sourceComponent: RegionPick.image.length > 0 ? imageComp : screencopyComp

            Component {
                id: imageComp
                Image {
                    anchors.fill: parent
                    source: "file://" + RegionPick.image
                    fillMode: Image.Stretch
                    asynchronous: false
                }
            }

            Component {
                id: screencopyComp
                ScreencopyView {
                    id: frozen
                    anchors.fill: parent
                    captureSource: picker.screen
                    live: false
                    paintCursor: false

                    onHasContentChanged: {
                        if (!hasContent)
                            return;

                        picker.aiming = true;
                        if (picker.releaseCaptureActive)
                            picker.save();
                    }
                }
            }
        }



        Loader {
            id: liveLoader
            anchors.fill: parent
            active: false
            asynchronous: true
            visible: false

            sourceComponent: ScreencopyView {
                anchors.fill: parent
                captureSource: picker.screen
                live: false
                paintCursor: false

                onHasContentChanged: {
                    if (!hasContent)
                        return;

                    picker.aiming = true;
                    if (picker.releaseCaptureActive)
                        picker.save();
                }
            }
        }

        Item {
            id: surface
            anchors.fill: parent
            focus: true

            Rectangle {
                x: 0; y: 0
                width: surface.width
                height: Math.max(0, picker.rsy)
                color: Theme.scrim
                opacity: 0.55
            }
            Rectangle {
                x: 0; y: picker.rsy + picker.sh
                width: surface.width
                height: Math.max(0, surface.height - picker.rsy - picker.sh)
                color: Theme.scrim
                opacity: 0.55
            }
            Rectangle {
                x: 0; y: picker.rsy
                width: Math.max(0, picker.rsx)
                height: picker.sh
                color: Theme.scrim
                opacity: 0.55
            }
            Rectangle {
                x: picker.rsx + picker.sw; y: picker.rsy
                width: Math.max(0, surface.width - picker.rsx - picker.sw)
                height: picker.sh
                color: Theme.scrim
                opacity: 0.55
            }

            Rectangle {
                x: picker.rsx
                y: picker.rsy
                width: picker.sw
                height: picker.sh
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
                        text: Math.round(picker.sw * picker.pxScale)
                            + " x " + Math.round(picker.sh * picker.pxScale)
                        color: Theme.on_primary
                        font {
                            family: Layout.fontSans
                            pixelSize: 13
                            weight: Font.Medium
                        }
                    }
                }
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: picker.aiming ? Qt.CrossCursor : Qt.BlankCursor


                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                onPressed: function(event) {
                    if (event.button === Qt.RightButton || event.button === Qt.MiddleButton) {
                        RegionPick.cancel();
                        return;
                    }
                    picker.dragging = true;
                    picker.onClient = false;
                    picker.anchorX = event.x;
                    picker.anchorY = event.y;
                    picker.sx = event.x;
                    picker.sy = event.y;
                    picker.ex = event.x;
                    picker.ey = event.y;
                }

                onPositionChanged: function(event) {
                    if (picker.dragging) {
                        picker.sx = picker.anchorX;
                        picker.sy = picker.anchorY;
                        picker.ex = event.x;
                        picker.ey = event.y;
                    } else {
                        picker.snapTo(event.x, event.y);
                    }
                }

                onReleased: {
                    if (!picker.dragging)
                        return;
                    picker.dragging = false;
                    if (picker.sw < 12 || picker.sh < 12) {
                        RegionPick.cancel();
                        return;
                    }
                    picker.releaseCaptureActive = true;
                    picker.save();
                }
            }

            Keys.onEscapePressed: function(event) {
                RegionPick.cancel();
                event.accepted = true;
            }
        }

        HyprlandFocusGrab {
            id: grab
            windows: [picker]
            onCleared: if (RegionPick.open)
                RegionPick.cancel()
        }

        Connections {
            target: RegionPick

            function onOpenChanged() {
                if (RegionPick.open) {
                    grab.active = true;
                } else {
                    grab.active = false;
                }
            }
        }

        Component.onCompleted: {
            grab.active = picker.picking;
            if (picker.picking)
                picker.onPickingChanged();
        }
    }
}
