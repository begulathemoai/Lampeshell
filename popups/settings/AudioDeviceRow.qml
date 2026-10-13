import QtQuick
import Quickshell.Services.Pipewire
import qs.services
import qs.theme

Item {
    id: root

    property var node: null
    property bool isActive: false
    property bool isInput: false
    property bool isFirst: true
    property bool isLast: true
    property real innerRadius: 5
    property real outerRadius: 20

    readonly property string label: {
        if (!root.node)
            return "";
        return root.node.description || root.node.nickname || root.node.name || "";
    }

    signal activated()

    function setGroupShape(first, last) {
        isFirst = first;
        isLast = last;
    }

    Rectangle {
        anchors.fill: parent
        z: -1
        color: rowMouse.containsMouse
            ? Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.06))
            : Theme.surface_container
        topLeftRadius: root.isFirst ? root.outerRadius : root.innerRadius
        topRightRadius: root.isFirst ? root.outerRadius : root.innerRadius
        bottomLeftRadius: root.isLast ? root.outerRadius : root.innerRadius
        bottomRightRadius: root.isLast ? root.outerRadius : root.innerRadius

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Layout.s(16)
        anchors.right: checkMark.left
        anchors.rightMargin: Layout.s(8)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Layout.s(14)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.isInput ? Audio.iconForSource(root.node) : Audio.iconForSink(root.node)
            color: root.isActive ? Theme.on_primary_container : Theme.on_surface_variant
            font { family: Layout.fontIcons; pixelSize: Layout.s(20) }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - Layout.s(34)
            text: root.label
            color: Theme.on_surface
            elide: Text.ElideRight
            font { family: Layout.fontSans; pixelSize: Layout.ts(13) }
        }
    }

    Text {
        id: checkMark
        anchors.right: parent.right
        anchors.rightMargin: Layout.s(16)
        anchors.verticalCenter: parent.verticalCenter
        text: "check"
        color: Theme.primary
        visible: root.isActive
        font { family: Layout.fontIcons; pixelSize: Layout.s(18) }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}