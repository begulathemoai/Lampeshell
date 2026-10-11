import QtQuick
import QtQuick.Controls
import qs.theme
import qs.services

/**
 * One wallpaper preview in the picker grid.
 *
 * The image is decoded at roughly the size it is drawn rather than at its full
 * resolution: a folder of 1440p/4k PNGs would otherwise decode tens of
 * megabytes per tile while scrolling. Decoding down to the tile size is what
 * keeps the grid responsive, and is why no separate thumbnail cache is needed -
 * the previous picker shelled out to a generate-thumbs.sh that does not exist on
 * this machine, which is why every preview came up blank.
 */
Item {
    id: root

    required property var entry
    required property string currentPath

    signal clicked

    readonly property string path: entry ? entry.path : ""
    readonly property bool isCurrent: path.length > 0 && path === currentPath

    readonly property int decodeWidth: 420

    implicitWidth: 180
    implicitHeight: tile.implicitHeight + label.implicitHeight + 6

    Rectangle {
        id: tile

        width: parent.width
        implicitHeight: Math.round(parent.width / 1.6)
        radius: 16
        color: Theme.surface_container_high
        border.width: root.isCurrent ? 2 : 1
        border.color: root.isCurrent ? Theme.primary : Theme.outline_variant
        clip: true

        scale: tileMouse.containsMouse && !root.isCurrent ? 1.02 : 1.0
        Behavior on scale {
            NumberAnimation {
                duration: 130
                easing.type: Easing.OutCubic
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: 130
            }
        }

        Image {
            id: preview

            anchors.fill: parent
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            cache: true
            sourceSize: Qt.size(root.decodeWidth, Math.round(root.decodeWidth / 1.6))
            source: root.path.length > 0 ? "file://" + root.path : ""
            opacity: status === Image.Ready ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 140
                }
            }
        }

        // Placeholder while decoding, and a broken-image mark if the file is
        Rectangle {
            anchors.fill: parent
            color: Theme.surface_container_highest
            visible: preview.status !== Image.Ready

            Text {
                anchors.centerIn: parent
                text: preview.status === Image.Error ? "broken_image" : "image"
                color: Theme.on_surface_variant
                opacity: 0.45
                font {
                    family: "Material Symbols Rounded"
                    pixelSize: 22
                }
            }
        }

        // "Current" badge, so it is obvious which wallpaper is applied.
        Rectangle {
            visible: root.isCurrent
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            width: 22
            height: 22
            radius: 11
            color: Theme.primary

            Text {
                anchors.centerIn: parent
                text: "check"
                color: Theme.on_primary
                font {
                    family: "Material Symbols Rounded"
                    pixelSize: 14
                }
            }
        }

        MouseArea {
            id: tileMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }
    }

    Text {
        id: label

        anchors.top: tile.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right
        horizontalAlignment: Text.AlignHCenter
        text: root.entry ? root.entry.name : ""
        elide: Text.ElideMiddle
        color: root.isCurrent ? Theme.primary : Theme.on_surface_variant
        font {
            family: "Google Sans"
            pixelSize: 11
            weight: root.isCurrent ? Font.Medium : Font.Normal
        }
    }
}
