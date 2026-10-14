import QtQuick
import qs.theme

Column {
    id: root

    property real hue: 0
    property real saturation: 0
    property real lightness: 0

    signal moved()

    readonly property color value: Qt.hsva(hue / 360, saturation, lightness, 1)

    width: parent ? parent.width : 0
    spacing: 8

    Rectangle {
        id: square
        width: root.width
        height: Math.min(Math.round(width), 190)
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
                orientation: Gradient.TopBottom
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
            anchors.verticalCenter: parent.verticalCenter
            height: 1
            color: Theme.on_surface
            opacity: 0.5
            y: (square.height - height) * (1 - root.lightness)
        }

        Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: 1
            color: Theme.on_surface
            opacity: 0.5
            x: (square.width - width) * root.saturation
        }

        Rectangle {
            width: 15
            height: 15
            radius: 7.5
            color: "transparent"
            border.width: 3
            border.color: Theme.on_surface
            x: (square.width - width) * root.saturation - width / 2
            y: (square.height - height) * (1 - root.lightness) - height / 2
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
        width: root.width
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
            width: 15
            height: 15
            radius: 7.5
            color: "transparent"
            border.width: 3
            border.color: Theme.on_surface
            x: (strip.width - width) * (root.hue / 360) - width / 2
            y: (strip.height - height) / 2
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
        root.saturation = Math.max(0, Math.min(1, mouse.x / Math.max(1, square.width)));
        root.lightness = Math.max(0, Math.min(1, 1 - mouse.y / Math.max(1, square.height)));
        root.moved();
    }

    function setHue(mouse) {
        root.hue = Math.max(0, Math.min(360, (mouse.x / Math.max(1, strip.width)) * 360));
        root.moved();
    }
}