import QtQuick
import QtQuick.Shapes
import qs.theme

// Circular progress ring used by the resource and performance cards.
Item {
    id: root

    property real value: 0 // 0..1
    property color fgColor: Theme.primary
    property color bgColor: Theme.surface_container_high
    property real strokeWidth: Layout.s(6)
    property int startAngle: -90
    property int sweepAngle: 360

    readonly property real size: Math.min(width, height)
    readonly property real arcRadius: (size - strokeWidth) / 2

    property real clamped: 0
    onValueChanged: clamped = Math.max(0, Math.min(1, value))
    Component.onCompleted: clamped = Math.max(0, Math.min(1, value))

    Behavior on clamped {
        NumberAnimation {
            duration: Motion.duration(Motion.defaultEffects)
            easing.type: Easing.OutCubic
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.bgColor
            strokeWidth: root.strokeWidth
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.arcRadius
                radiusY: root.arcRadius
                startAngle: root.startAngle
                sweepAngle: root.sweepAngle
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.fgColor
            strokeWidth: root.strokeWidth
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.arcRadius
                radiusY: root.arcRadius
                startAngle: root.startAngle
                sweepAngle: root.sweepAngle * root.clamped
            }
        }
    }
}
