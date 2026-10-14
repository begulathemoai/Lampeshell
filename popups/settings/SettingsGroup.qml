import QtQuick
import qs.theme

Item {
    id: root

    property string title: ""
    property string description: ""

    default property alias rows: rowsColumn.data

    width: parent ? parent.width : 0
    height: outerColumn.implicitHeight

    readonly property int rowCount: rowsColumn.children.length

    function applyShape() {
        const rows = [];
        for (const child of rowsColumn.children) {
            if (child && typeof child.setGroupShape === "function")
                rows.push(child);
        }
        for (let i = 0; i < rows.length; i++)
            rows[i].setGroupShape(i === 0, i === rows.length - 1);
    }

    onRowCountChanged: applyShape()
    Component.onCompleted: applyShape()

    Column {
        id: outerColumn
        width: parent.width
        spacing: 0

        Text {
            id: groupTitle
            width: parent.width
            visible: root.title.length > 0
            text: root.title
            elide: Text.ElideRight
            color: Theme.primary
            font {
                family: Layout.fontSans
                pixelSize: 14
                weight: Font.Medium
            }
            topPadding: 8
            bottomPadding: 12
            rightPadding: 32
        }

        Text {
            width: parent.width
            visible: root.description.length > 0
            text: root.description
            wrapMode: Text.WordWrap
            color: Theme.on_surface_variant
            opacity: 0.75
            font {
                family: Layout.fontSans
                pixelSize: 12
            }
            bottomPadding: 12
        }

        Column {
            id: rowsColumn
            width: parent.width
            spacing: Layout.connectedSpacing
        }
    }
}
