import QtQuick
import qs.theme

Item {
    id: root

    property string text: ""
    property string description: ""

    implicitHeight: col.implicitHeight

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 2

        Text {
            text: root.text
            elide: Text.ElideRight
            color: Theme.primary
            font {
                family: Layout.fontSans
                pixelSize: 14
                weight: Font.Medium
            }
        }

        Text {
            width: parent.width
            visible: root.description.length > 0
            text: root.description
            wrapMode: Text.WordWrap
            color: Theme.on_surface_variant
            opacity: 0.75
            font {
                family: Layout.fontSans
                pixelSize: 12
            }
        }
    }
}
