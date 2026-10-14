import QtQuick
import QtQuick.Controls
import qs.theme

Item {
    id: root

    property alias text: input.text
    property string placeholder: "Search settings"

    signal cleared

    implicitHeight: 56

    function clear() {
        input.text = "";
        root.cleared();
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: height / 2
        color: Theme.surface_container_highest
        border.width: input.activeFocus ? 3 : 0
        border.color: Theme.primary

        Behavior on border.width {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        Text {
            id: searchIcon
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: "search"
            color: Theme.on_surface_variant
            font {
                family: Layout.fontIcons
                pixelSize: 22
            }
        }

        TextField {
            id: input
            anchors.left: searchIcon.right
            anchors.leftMargin: 12
            anchors.right: clearButton.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            background: null
            padding: 0
            placeholderText: root.placeholder
            placeholderTextColor: Theme.on_surface_variant
            color: Theme.on_surface
            selectByMouse: true
            font {
                family: Layout.fontSans
                pixelSize: 16
            }
            cursorDelegate: Rectangle {
                width: 2
                color: Theme.primary
            }
        }

        Item {
            id: clearButton
            visible: input.text.length > 0
            width: visible ? 36 : 0
            height: 36
            anchors.right: parent.right
            anchors.rightMargin: visible ? 10 : 0
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.centerIn: parent
                width: 32
                height: 32
                radius: 16
                color: clearMouse.containsMouse
                    ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.10)
                    : "transparent"
            }

            Text {
                anchors.centerIn: parent
                text: "close"
                color: Theme.on_surface_variant
                font {
                    family: Layout.fontIcons
                    pixelSize: 20
                }
            }

            MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.clear()
            }
        }
    }
}
