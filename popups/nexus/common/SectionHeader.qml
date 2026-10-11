import QtQuick
import qs.theme

/** Small heading used to break a page body into labelled groups. */
Item {
    id: root

    property string text: ""
    property string description: ""

    implicitHeight: col.implicitHeight

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 1

        Text {
            text: root.text
            color: Theme.on_surface_variant
            font {
                family: "Google Sans"
                pixelSize: 11
                weight: Font.Medium
                capitalization: Font.AllUppercase
                letterSpacing: 0.8
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
                family: "Google Sans"
                pixelSize: 11
            }
        }
    }
}
