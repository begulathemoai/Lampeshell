import QtQuick
import qs.theme

Item {
    id: root

    property string label: ""
    property var model: []
    property string value: ""
    property bool isFirst: true
    property bool isLast: true
    property bool enabled: true

    signal selected(string value)

    function setGroupShape(first, last) {
        isFirst = first;
        isLast = last;
    }

    readonly property real outerRadius: 20
    readonly property real innerRadius: 5

    Rectangle {
        anchors.fill: parent
        z: -1
        color: Theme.surface_container
        topLeftRadius: root.isFirst ? root.outerRadius : root.innerRadius
        topRightRadius: root.isFirst ? root.outerRadius : root.innerRadius
        bottomLeftRadius: root.isLast ? root.outerRadius : root.innerRadius
        bottomRightRadius: root.isLast ? root.outerRadius : root.innerRadius
    }

    implicitHeight: 48
    width: parent ? parent.width : 0

    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * 0.4
        text: root.label
        color: Theme.on_surface_variant
        font {
            family: "Google Sans"
            pixelSize: 12
        }
    }

    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Repeater {
            model: root.model

            delegate: Rectangle {
                id: chip

                required property var modelData
                required property int index

                readonly property bool active: root.value === modelData.value

                implicitWidth: chipLabel.implicitWidth + 20
                implicitHeight: 28
                radius: height / 2

                opacity: root.enabled ? 1 : 0.4

                color: active
                    ? (chipMouse.containsMouse
                        ? Qt.lighter(Theme.primary_container, 1.08)
                        : Theme.primary_container)
                    : (chipMouse.containsMouse
                        ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.10)
                        : Theme.surface_container_highest)

                Behavior on color {
                    ColorAnimation {
                        duration: 110
                    }
                }

                Text {
                    id: chipLabel
                    anchors.centerIn: parent
                    text: chip.modelData.label
                    color: chip.active ? Theme.on_primary_container : Theme.on_surface
                    font {
                        family: "Google Sans"
                        pixelSize: 12
                        weight: Font.Medium
                    }
                }

                MouseArea {
                    id: chipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.enabled
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selected(chip.modelData.value)
                }
            }
        }
    }
}