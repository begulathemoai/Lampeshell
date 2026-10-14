import QtQuick
import QtQuick.Controls
import qs.theme

Item {
    id: root

    property string label: ""
    property string bindText: ""
    property bool isFirst: true
    property bool isLast: true

    signal edited(string text)

    function setGroupShape(first, last) {
        root.isFirst = first;
        root.isLast = last;
    }

    readonly property real outerRadius: Layout.connectedOuterRadius
    readonly property real innerRadius: Layout.connectedInnerRadius

    readonly property bool invalid: bindInput.text.length > 0 && /["'\\{}#;\n\r]/.test(bindInput.text)

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
        color: Theme.surface_container_highest
        border.width: bindInput.activeFocus ? 2 : 1
        border.color: root.invalid ? Theme.critical : (bindInput.activeFocus ? Theme.primary : Theme.outline_variant)

        Behavior on border.color {
            ColorAnimation {
                duration: 120
            }
        }

        TextInput {
            id: bindInput
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            verticalAlignment: TextInput.AlignVCenter
            text: root.bindText
            color: Theme.on_surface
            selectionColor: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4)
            selectedTextColor: Theme.on_primary
            font {
                family: Layout.fontSans
                pixelSize: 13
            }

            onTextChanged: root.edited(text)
        }
    }
}
