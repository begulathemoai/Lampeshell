import QtQuick
import qs.theme

/**
 * Read-only label/value pair for the About and system pages.
 */
Item {
    id: root

    property string label: ""
    property string value: ""

    // --- Settings group chrome ---
    // Connected corners when placed inside a SettingsGroup (assigned by the
    // group), matching Metrolist's connectedShape.
    property bool isFirst: true
    property bool isLast: true

    function setGroupShape(first, last) {
        isFirst = first;
        isLast = last;
    }

    readonly property real outerRadius: 20
    readonly property real innerRadius: 5

    Rectangle {
        id: groupSurface
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

    Text {
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.4
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideRight
        text: root.value
        color: Theme.on_surface
        font {
            family: "Google Sans"
            pixelSize: 12
            weight: Font.Medium
        }
    }
}