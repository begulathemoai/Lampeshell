import QtQuick
import qs.theme

/**
 * Card container for the settings pages: title, optional subtitle, and a body
 * slot. Mirrors the surface layering used across the shell so pages read as a
 * stack of raised panels rather than a flat form.
 */
Item {
    id: root

    property string title: ""
    property string subtitle: ""
    default property alias content: body.data

    // Cards are laid out inside a plain Column, which does not stretch children
    // to its width. Without this the card measures 0 wide and the whole card
    // collapses - which is why page bodies rendered blank. Every other row
    // component in this folder already fills its parent.
    width: parent ? parent.width : 0
    implicitHeight: body.implicitHeight + (title ? 34 : 0) + 34

    Rectangle {
        anchors.fill: parent
        radius: 20
        // surface_container, not surface_container_high: group rows already sit
        // on surface_container, and a lighter fill made these blocks read as a
        // different, heavier surface. Metrolist keeps custom blocks on the same
        // tone as the rows around them.
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
        anchors.margins: 16
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