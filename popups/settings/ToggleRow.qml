import QtQuick
import qs.theme
import "."

Item {
    id: root

    property string icon: ""
    property string label: ""
    property string description: ""
    property bool checked: false
    property bool enabled: true

    signal toggled(bool checked)

    width: parent ? parent.width : 0
    height: row.height

    function setGroupShape(first, last) {
        row.setGroupShape(first, last);
    }

    SettingsRow {
        id: row

        width: parent.width
        icon: root.icon
        label: root.label
        description: root.description
        enabled: root.enabled
        onClicked: root.toggled(!root.checked)

        Switch {
            checked: root.checked
            enabled: root.enabled
            onToggled: next => root.toggled(next)
        }
    }
}
