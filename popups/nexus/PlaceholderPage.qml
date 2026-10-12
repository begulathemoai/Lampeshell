import QtQuick
import qs.theme
import qs.popups.nexus

Item {
    id: root

    required property NexusState nState

    implicitHeight: 220

    Column {
        anchors.centerIn: parent
        width: parent.width * 0.7
        spacing: 8

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "handyman"
            color: Theme.on_surface_variant
            opacity: 0.6
            font {
                family: "Material Symbols Rounded"
                pixelSize: 38
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Not set up yet"
            color: Theme.on_surface_variant
            font {
                family: "Google Sans"
                pixelSize: 15
                weight: Font.Medium
            }
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: "This section is registered but has no page yet."
            color: Theme.on_surface_variant
            opacity: 0.75
            font {
                family: "Google Sans"
                pixelSize: 12
            }
        }
    }
}
