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
        const kids = rowsColumn.children;
        for (let i = 0; i < kids.length; i++) {
            const row = kids[i];
            if (row && typeof row.setGroupShape === "function")
                row.setGroupShape(i === 0, i === kids.length - 1);
        }
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
                family: "Google Sans"
                pixelSize: 12
                weight: Font.Medium
            }
            topPadding: 8
            bottomPadding: 12
            leftPadding: 16
        }

        Text {
            width: parent.width
            visible: root.description.length > 0
            text: root.description
            wrapMode: Text.WordWrap
            color: Theme.on_surface_variant
            opacity: 0.75
            font {
                family: "Google Sans"
                pixelSize: 12
            }
            leftPadding: 16
            rightPadding: 16
            bottomPadding: 10
        }

        Column {
            id: rowsColumn
            width: parent.width
            spacing: 4
        }
    }
}
