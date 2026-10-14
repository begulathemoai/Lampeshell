import QtQuick
import QtQuick.Effects
import M3Shapes
import qs.theme

Item {
    id: root

    property url source: ""
    property int shape: MaterialShape.Cookie12Sided
    property color fallbackColor: Theme.surface_container_high
    property string fallbackIcon: "music_note"
    property real fallbackIconSize: Layout.s(48)
    property bool rotate: true
    property bool spinning: false
    property int spinDuration: 23500

    Item {
        id: shapeWrapper

        anchors.fill: parent
        layer.enabled: true

        MaterialShape {
            id: shape

            anchors.centerIn: parent
            width: implicitSize
            height: implicitSize
            implicitSize: Math.min(root.width, root.height)
            shape: root.shape
            color: root.fallbackColor

            RotationAnimation on rotation {
                running: root.rotate && root.spinning
                from: 360
                to: 0
                duration: root.spinDuration
                loops: Animation.Infinite
                easing.type: Easing.Linear
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: !image.visible
        text: root.fallbackIcon
        color: Theme.on_surface_variant
        font {
            family: Layout.fontIcons
            pixelSize: root.fallbackIconSize
        }
    }

    Image {
        id: image

        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: status === Image.Ready

        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSpreadAtMin: 1
            maskThresholdMin: 0.5
            maskSource: shapeWrapper
        }
    }
}
