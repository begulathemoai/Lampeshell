import QtQuick
import qs.theme

Item {
    id: root

    required property var entry
    property bool isFirst: true
    property bool isLast: true

    signal clicked

    function setGroupShape(first, last) {
        isFirst = first;
        isLast = last;
    }

    width: parent ? parent.width : 0
    height: Math.max(72, content.implicitHeight + 32)

    readonly property real outerRadius: Layout.connectedOuterRadius
    readonly property real innerRadius: Layout.connectedInnerRadius

    Rectangle {
        anchors.fill: parent
        color: rowMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container
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
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Row {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 16

        Item {
            width: 32
            height: 32
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                text: root.entry.icon ?? "settings"
                color: Theme.on_surface_variant
                font {
                    family: Layout.fontIcons
                    pixelSize: 24
                }
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 48 - 24
            spacing: 2

            Text {
                width: parent.width
                text: root.entry.title ?? ""
                elide: Text.ElideRight
                color: Theme.on_surface
                font {
                    family: Layout.fontSans
                    pixelSize: 16
                }
            }

            Text {
                width: parent.width
                visible: (root.entry.desc ?? "") !== ""
                text: root.entry.desc ?? ""
                elide: Text.ElideRight
                color: Theme.on_surface_variant
                font {
                    family: Layout.fontSans
                    pixelSize: 14
                }
            }

            Text {
                width: parent.width
                visible: !root.entry.isPage && (root.entry.desc ?? "") !== ""
                text: root.entry.page ?? ""
                elide: Text.ElideRight
                color: Theme.on_surface_variant
                font {
                    family: Layout.fontSans
                    pixelSize: 12
                }
            }
        }

        Item {
            width: 24
            height: 24
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                text: "chevron_right"
                color: Theme.on_surface_variant
                font {
                    family: Layout.fontIcons
                    pixelSize: 20
                }
            }
        }
    }
}
