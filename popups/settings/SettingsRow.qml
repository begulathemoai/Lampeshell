import QtQuick
import qs.theme

Item {
    id: root

    property string icon: ""
    property string label: ""
    property string description: ""
    property bool enabled: true
    property bool showIcon: true

    property bool isFirst: true
    property bool isLast: true

    default property alias trailing: trailingHolder.data

    signal clicked

    width: parent ? parent.width : 0
    height: 16 + (labelText.implicitHeight + (descriptionText.visible ? 2 + descriptionText.implicitHeight : 0)) + 16

    opacity: enabled ? 1.0 : 0.38

    readonly property real outerRadius: 20
    readonly property real innerRadius: 5

    function setGroupShape(first, last) {
        isFirst = first;
        isLast = last;
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: "transparent"

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: rowMouse.pressed ? Theme.surface_container_high : Theme.surface_container
        topLeftRadius: root.isFirst ? root.outerRadius : root.innerRadius
        topRightRadius: root.isFirst ? root.outerRadius : root.innerRadius
        bottomLeftRadius: root.isLast ? root.outerRadius : root.innerRadius
        bottomRightRadius: root.isLast ? root.outerRadius : root.innerRadius

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }

    Rectangle {
        id: iconContainer
        visible: root.showIcon && root.icon.length > 0
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        width: 32
        height: 32
        radius: 16
        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1)

        Text {
            anchors.centerIn: parent
            text: root.icon
            color: Theme.primary
            opacity: 0.9
            font {
                family: "Material Symbols Rounded"
                pixelSize: 24
            }
        }
    }

    Column {
        anchors.left: iconContainer.visible ? iconContainer.right : parent.left
        anchors.leftMargin: iconContainer.visible ? 16 : 16
        anchors.right: trailingHolder.left
        anchors.rightMargin: trailingHolder.width > 0 ? 8 : 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Text {
            id: labelText
            width: parent.width
            text: root.label
            elide: Text.ElideRight
            color: Theme.on_surface
            font {
                family: "Google Sans"
                pixelSize: 15
                weight: Font.Normal
            }
        }

        Text {
            id: descriptionText
            width: parent.width
            visible: root.description.length > 0
            text: root.description
            elide: Text.ElideRight
            color: Theme.on_surface_variant
            font {
                family: "Google Sans"
                pixelSize: 13
            }
        }
    }

    Item {
        id: trailingHolder
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
}
