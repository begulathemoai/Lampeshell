import QtQuick
import "../../theme"
import qs.services

Item {
    id: root

    required property var modelData

    scale: 0.5
    opacity: 0
    z: PathView.z ?? 0

    Component.onCompleted: {
        scale = Qt.binding(() => PathView.isCurrentItem ? 1 : PathView.onPath ? 0.8 : 0);
        opacity = Qt.binding(() => PathView.onPath ? 1 : 0);
    }

    implicitWidth: image.width + Layout.s(16)
    implicitHeight: image.height + label.height + Layout.s(8) + Layout.s(12)

    Rectangle {
        id: image

        anchors.horizontalCenter: parent.horizontalCenter
        y: Layout.s(12)
        color: Theme.surface_container
        radius: Layout.s(16)

        implicitWidth: 280
        implicitHeight: implicitWidth / 16 * 9

        clip: true

        Image {
            anchors.fill: parent
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            cache: true
            source: root.modelData && root.modelData.path ? "file://" + root.modelData.path : ""
            smooth: !root.PathView.view.moving

            Rectangle {
                anchors.centerIn: parent
                width: 48
                height: 48
                radius: 24
                color: Theme.surface_container_high
                visible: parent.status !== Image.Ready

                Text {
                    anchors.centerIn: parent
                    text: "image"
                    color: Theme.on_surface_variant
                    font {
                        family: "Material Symbols Rounded"
                        pixelSize: 24
                    }
                }
            }
        }
    }

    Text {
        id: label

        anchors.top: image.bottom
        anchors.topMargin: Layout.s(8)
        anchors.horizontalCenter: parent.horizontalCenter

        width: image.width - Layout.s(16)
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: root.modelData ? (root.modelData.category ? root.modelData.category + " / " + root.modelData.name : root.modelData.name) : ""
        color: Theme.on_surface
        font {
            family: "Google Sans"
            pixelSize: 12
            weight: Font.Medium
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.modelData && root.modelData.path)
                ThemeService.applyWallpaper(root.modelData.path);
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Motion.duration(Motion.standard)
            easing.type: Easing.OutCubic
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Motion.duration(Motion.standard)
            easing.type: Easing.OutCubic
        }
    }
}
