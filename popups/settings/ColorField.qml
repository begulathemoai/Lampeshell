import QtQuick
import qs.theme

Item {
    id: root

    property real hue: 0
    property real saturation: 0
    property real lightness: 0

    signal picked(real hue, real saturation, real lightness)

    readonly property color value: Qt.hsva(hue / 360, saturation, lightness, 1)

    width: parent ? parent.width : 0
    height: side + 8 + 24

    readonly property real side: Math.max(1, Math.min(width, 190))
    readonly property real inset: (width - side) / 2

    Rectangle {
        id: square
        x: root.inset
        y: 0
        width: root.side
        height: root.side
        radius: 12
        clip: true
        border.width: 1
        border.color: Theme.outline_variant

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.0
                    color: "#ffffff"
                }
                GradientStop {
                    position: 1.0
                    color: Qt.hsva(root.hue / 360, 1, 1, 1)
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop {
                    position: 0.0
                    color: "#00000000"
                }
                GradientStop {
                    position: 1.0
                    color: "#ff000000"
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Theme.on_surface
            opacity: 0.5
            y: Math.max(0, Math.min(square.height - height, square.height * (1 - root.lightness) - height / 2))
        }

        Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: Theme.on_surface
            opacity: 0.5
            x: Math.max(0, Math.min(square.width - width, square.width * root.saturation - width / 2))
        }

        Rectangle {
            x: Math.max(0, Math.min(square.width - width, square.width * root.saturation - width / 2))
            y: Math.max(0, Math.min(square.height - height, square.height * (1 - root.lightness) - height / 2))
            width: 15
            height: 15
            radius: 7.5
            color: "transparent"
            border.width: 3
            border.color: Theme.on_surface
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.CrossCursor
            preventStealing: true
            onPressed: function(mouse) {
                root.apply(mouse);
            }
            onPositionChanged: function(mouse) {
                if (pressed)
                    root.apply(mouse);
            }
        }
    }

    Rectangle {
        id: strip
        x: root.inset
        y: root.side + 8
        width: root.side
        height: 24
        radius: 12
        clip: true
        border.width: 1
        border.color: Theme.outline_variant

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0.0
                color: "#ff0000"
            }
            GradientStop {
                position: 0.167
                color: "#ffff00"
            }
            GradientStop {
                position: 0.333
                color: "#00ff00"
            }
            GradientStop {
                position: 0.5
                color: "#00ffff"
            }
            GradientStop {
                position: 0.667
                color: "#0000ff"
            }
            GradientStop {
                position: 0.833
                color: "#ff00ff"
            }
            GradientStop {
                position: 1.0
                color: "#ff0000"
            }
        }

        Rectangle {
            x: Math.max(0, Math.min(strip.width - width, strip.width * (root.hue / 360) - width / 2))
            y: (strip.height - height) / 2
            width: 15
            height: 15
            radius: 7.5
            color: "transparent"
            border.width: 3
            border.color: Theme.on_surface
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            preventStealing: true
            onPressed: function(mouse) {
                root.setHue(mouse);
            }
            onPositionChanged: function(mouse) {
                if (pressed)
                    root.setHue(mouse);
            }
        }
    }

    function apply(mouse) {
        const s = Math.max(0, Math.min(1, mouse.x / Math.max(1, square.width)));
        const l = Math.max(0, Math.min(1, 1 - mouse.y / Math.max(1, square.height)));
        root.picked(root.hue, s, l);
    }

    function setHue(mouse) {
        const h = Math.max(0, Math.min(360, (mouse.x / Math.max(1, strip.width)) * 360));
        root.picked(h, root.saturation, root.lightness);
    }
}