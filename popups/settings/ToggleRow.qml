import QtQuick
import qs.theme
import "."

 * Labelled on/off row.
 *
 * Built from SettingsRow plus the shell's own Switch rather than
 * QtQuick.Controls' Switch, which renders with the platform style and did not
 * match the rest of the Material 3 surfaces.
 *
 * Reports the switch's *new* state so the backend sets the requested value
 * explicitly instead of flipping whatever it last read (Caelestia's pattern).
 * `checked` is never written here - the backend pushes the authoritative value
 * back.
 */
Item {
    id: root

    property string icon: ""
    property string label: ""
    property string description: ""
    property bool checked: false
    property bool enabled: true
    // Real signal - see ActionButton.qml for why a `property var onToggled`
    signal toggled(bool checked)

    width: parent ? parent.width : 0
    height: row.height

    // Forward the group's connected-corner flags to the row that draws them.
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
