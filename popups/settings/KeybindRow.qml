import QtQuick
import QtQuick.Controls
import qs.theme
import qs.services

Item {
    id: root

    property string label: ""
    property string bindText: ""
    property bool isFirst: true
    property bool isLast: true
    property string bindKey: ""
    property var clashes: []

    signal edited(string text)
    signal picked()

    function setGroupShape(first, last) {
        root.isFirst = first;
        root.isLast = last;
    }

    readonly property real outerRadius: Layout.connectedOuterRadius
    readonly property real innerRadius: Layout.connectedInnerRadius

    width: parent ? parent.width : 0
    implicitHeight: Layout.rowMinHeight

    Rectangle {
        anchors.fill: parent
        color: Theme.surface_container
        topLeftRadius: root.isFirst ? root.outerRadius : root.innerRadius
        topRightRadius: root.isFirst ? root.outerRadius : root.innerRadius
        bottomLeftRadius: root.isLast ? root.outerRadius : root.innerRadius
        bottomRightRadius: root.isLast ? root.outerRadius : root.innerRadius
    }

    Text {
        id: labelText
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.right: field.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        elide: Text.ElideRight
        color: Theme.on_surface
        font {
            family: Layout.fontSans
            pixelSize: 15
        }
    }

    Rectangle {
        id: field

        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(150, Math.min(300, parent.width * 0.36))
        height: 38
        radius: 19
        color: fieldMouse.containsMouse
            ? Theme.surface_container_high
            : Theme.surface_container_highest
        border.width: root.clashes.length > 0 ? 2 : 1
        border.color: root.clashes.length > 0
            ? Theme.critical
            : (fieldMouse.containsMouse ? Theme.primary : Theme.outline_variant)

        Behavior on border.color {
            ColorAnimation {
                duration: 120
            }
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.right: hint.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, field.width - 90)
                text: root.bindText.length > 0 ? root.bindText : "Unbound"
                color: root.bindText.length > 0 ? Theme.on_surface : Theme.on_surface_variant
                elide: Text.ElideRight
                font {
                    family: Layout.fontSans
                    pixelSize: 13
                }
            }
        }

        Text {
            id: hint

            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: root.clashes.length > 0 ? "conflict" : "tune"
            color: root.clashes.length > 0 ? Theme.critical : Theme.on_surface_variant
            opacity: 0.75
            font {
                family: root.clashes.length > 0 ? Layout.fontSans : Layout.fontIcons
                pixelSize: root.clashes.length > 0 ? 11 : 14
            }
        }

        MouseArea {
            id: fieldMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.picked()
        }
    }
}
