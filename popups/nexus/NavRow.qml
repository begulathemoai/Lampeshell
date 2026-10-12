import QtQuick
import qs.theme

Item {
    id: root

    required property var page
    required property bool selected
    property bool isFirst: true
    property bool isLast: true

    signal clicked

    function setGroupShape(first, last) {
        isFirst = first;
        isLast = last;
    }

    width: parent ? parent.width : 0
    height: Math.max(64, content.implicitHeight + 24)

    readonly property real outerRadius: 20
    readonly property real innerRadius: 5

    Rectangle {
        anchors.fill: parent
        color: root.selected ? Theme.secondary_container : Theme.surface_container
        topLeftRadius: root.isFirst ? root.outerRadius : root.innerRadius
        topRightRadius: root.isFirst ? root.outerRadius : root.innerRadius
        bottomLeftRadius: root.isLast ? root.outerRadius : root.innerRadius
        bottomRightRadius: root.isLast ? root.outerRadius : root.innerRadius

        Behavior on color {
            ColorAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Row {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 16

        Item {
            width: 32
            height: 32

            Text {
                anchors.centerIn: parent
                text: root.page.icon ?? ""
                color: Theme.on_surface_variant
                font {
                    family: "Material Symbols Rounded"
                    pixelSize: 24
                }
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 48
            spacing: 2

            Text {
                width: parent.width
                text: root.page.label ?? ""
                elide: Text.ElideRight
                color: Theme.on_surface
                font {
                    family: "Google Sans"
                    pixelSize: 15

                    weight: root.selected ? Font.DemiBold : Font.Normal
                }
            }

            Text {
                width: parent.width
                visible: (root.page.description ?? "") !== ""
                text: root.page.description ?? ""
                elide: Text.ElideRight
                color: Theme.on_surface_variant
                font {
                    family: "Google Sans"
                    pixelSize: 13
                }
            }
        }
    }
}
