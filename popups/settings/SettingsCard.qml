import QtQuick
import qs.theme

Item {
    id: root

    property string title: ""
    property string subtitle: ""
    default property alias content: body.data

    width: parent ? parent.width : 0
    readonly property int margin: 16
    implicitHeight: body.implicitHeight + margin * 2

    Rectangle {
        anchors.fill: parent
        radius: 20

        color: Theme.surface_container
        border.width: 1
        border.color: Theme.outline_variant
        opacity: 0.99
    }

    Column {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.margin
        spacing: 12

        Column {
            width: parent.width
            spacing: 2
            visible: root.title !== ""

            Text {
                text: root.title
                color: Theme.on_surface
                font {
                    family: "Google Sans"
                    pixelSize: 14
                    weight: Font.Medium
                }
            }

            Text {
                width: parent.width
                text: root.subtitle
                visible: root.subtitle !== ""
                color: Theme.on_surface_variant
                wrapMode: Text.WordWrap
                font {
                    family: "Google Sans"
                    pixelSize: 11
                }
            }
        }
    }
}
