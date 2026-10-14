import QtQuick
import QtQuick.Controls
import qs.theme
import qs.services
import qs.popups.nexus.common

Item {
    id: root

    property string bindKey: ""
    property string bindLabel: ""
    property var combos: []
    property int editingIndex: 0

    property bool open: false

    readonly property var current: root.editingIndex < root.combos.length
        ? root.combos[root.editingIndex]
        : ""

    readonly property var parts: Keybinds.partsOf(root.current)
    property var mods: []

    property bool typing: false
    property string typed: ""

    readonly property var clashes: Keybinds.conflictsFor(root.current, root.bindKey)

    signal applied(string text)
    signal dismissed()

    opacity: root.open ? 1 : 0
    visible: root.open || opacity > 0.001

    Behavior on opacity {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    function openFor(key, label, text) {
        root.bindKey = key;
        root.bindLabel = label;
        root.combos = Keybinds.splitList(text);
        if (root.combos.length === 0)
            root.combos = [""];
        root.editingIndex = 0;
        root.mods = Keybinds.partsOf(root.combos[0]).mods;
        root.typing = false;
        root.typed = "";
        root.open = true;
    }

    function close() {
        root.open = false;
    }

    function refreshParts() {
        root.mods = Keybinds.partsOf(root.combos[root.editingIndex] ?? "").mods;
        root.typed = root.combos[root.editingIndex] ?? "";
    }

    function toggleMod(name) {
        const next = root.mods.slice();
        const at = next.indexOf(name);
        if (at >= 0)
            next.splice(at, 1);
        else
            next.push(name);
        root.mods = next;
        root.setCurrent(Keybinds.compose(next, root.parts.key));
    }

    function chooseKey(name) {
        root.setCurrent(Keybinds.compose(root.mods, name));
    }

    function setCurrent(value) {
        const next = root.combos.slice();
        while (next.length <= root.editingIndex)
            next.push("");
        next[root.editingIndex] = value;
        root.combos = next;
    }

    function addCombo() {
        root.combos = root.combos.concat([""]);
        root.editingIndex = root.combos.length - 1;
        root.mods = [];
        root.typed = "";
        root.typing = false;
    }

    function removeComboAt(i) {
        if (root.combos.length <= 1)
            return;
        const next = root.combos.slice();
        next.splice(i, 1);
        root.combos = next;
        root.editingIndex = 0;
        root.refreshParts();
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.close();
                root.dismissed();
            }
        }
    }

    Rectangle {
        id: sheet

        anchors.centerIn: parent
        width: Math.min(parent.width - 40, 620)
        height: Math.min(parent.height - 40, 660)
        radius: 26
        color: Theme.surface_container

        border.width: 1
        border.color: Theme.outline_variant

        Column {
            id: body

            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            Text {
                id: titleText

                width: parent.width
                text: root.bindLabel
                color: Theme.on_surface
                elide: Text.ElideRight
                font {
                    family: Layout.fontSans
                    pixelSize: 17
                    weight: Font.Medium
                }
            }

            Flow {
                id: comboRow

                width: parent.width
                spacing: 8

                Repeater {
                    model: root.combos.length

                    delegate: Rectangle {
                        id: comboChip

                        required property int index

                        readonly property bool active: index === root.editingIndex
                        readonly property string combo: root.combos[index] ?? ""

                        height: 34
                        width: chipRow.implicitWidth + 26
                        radius: 17
                        color: active ? Theme.primary : Theme.surface_container_highest
                        border.width: 1
                        border.color: active ? Theme.primary : Theme.outline_variant

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.editingIndex = comboChip.index;
                                root.refreshParts();
                            }
                        }

                        Row {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.min(implicitWidth, 210)
                                text: comboChip.combo.length > 0 ? comboChip.combo : "empty"
                                color: comboChip.active
                                    ? Theme.on_primary
                                    : Theme.on_surface_variant
                                elide: Text.ElideRight
                                font {
                                    family: Layout.fontSans
                                    pixelSize: 12
                                    weight: comboChip.active ? Font.Medium : Font.Normal
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: root.combos.length > 1
                                text: "close"
                                color: comboChip.active
                                    ? Theme.on_primary
                                    : Theme.on_surface_variant
                                opacity: 0.7
                                font {
                                    family: Layout.fontIcons
                                    pixelSize: 13
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.removeComboAt(comboChip.index)
                                }
                            }
                        }

                    }
                }
            }

            Rectangle {
                id: previewRect

                width: parent.width
                height: 46
                radius: 23
                color: Theme.surface_container_highest
                border.width: 2
                border.color: root.clashes.length > 0 ? Theme.critical : Theme.primary

                Text {
                    id: preview

                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.right: previewHint.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.current.length > 0 ? root.current : "Pick a combination"
                    color: root.current.length > 0
                        ? Theme.on_surface
                        : Theme.on_surface_variant
                    elide: Text.ElideRight
                    font {
                        family: Layout.fontSans
                        pixelSize: 14
                        weight: Font.Medium
                    }
                }

                Text {
                    id: previewHint

                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.clashes.length > 0
                        ? "used by " + root.clashes.length + " more"
                        : "Hyprland"
                    color: root.clashes.length > 0
                        ? Theme.critical
                        : Theme.on_surface_variant
                    font {
                        family: Layout.fontSans
                        pixelSize: 11
                    }
                }
            }

            Flow {
                id: modRow

                width: parent.width
                spacing: 8

                Repeater {
                    model: Keybinds.modifierList

                    delegate: Rectangle {
                        id: modChip

                        required property string modelData

                        readonly property bool on: root.mods.indexOf(modelData) >= 0

                        height: 36
                        width: modLabel.implicitWidth + 28
                        radius: 18
                        color: on ? Theme.primary : Theme.surface_container_highest
                        border.width: 1
                        border.color: on ? Theme.primary : Theme.outline_variant

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

                        Text {
                            id: modLabel
                            anchors.centerIn: parent
                            text: modChip.modelData
                            color: modChip.on ? Theme.on_primary : Theme.on_surface_variant
                            font {
                                family: Layout.fontSans
                                pixelSize: 12
                                weight: modChip.on ? Font.Medium : Font.Normal
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleMod(modChip.modelData)
                        }
                    }
                }

                Rectangle {
                    height: 36
                    width: addLabel.implicitWidth + 28
                    radius: 18
                    color: Theme.surface_container
                    border.width: 1
                    border.color: Theme.outline_variant

                    Text {
                        id: addLabel
                        anchors.centerIn: parent
                        text: "+ add another"
                        color: Theme.on_surface_variant
                        font {
                            family: Layout.fontSans
                            pixelSize: 12
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.addCombo()
                    }
                }

                Rectangle {
                    height: 36
                    width: typeLabel.implicitWidth + 28
                    radius: 18
                    color: Theme.surface_container
                    border.width: 1
                    border.color: Theme.outline_variant

                    Text {
                        id: typeLabel
                        anchors.centerIn: parent
                        text: root.typing ? "use the grid" : "type instead"
                        color: Theme.on_surface_variant
                        font {
                            family: Layout.fontSans
                            pixelSize: 12
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.typed = root.current;
                            root.typing = !root.typing;
                        }
                    }
                }
            }

            Rectangle {
                id: typedRect

                width: parent.width
                height: root.typing ? 44 : 0
                radius: 22
                color: Theme.surface_container_highest
                border.width: root.typing && typedInput.activeFocus ? 2 : (root.typing ? 1 : 0)
                border.color: root.typing
                    ? (typedInput.activeFocus ? Theme.primary : Theme.outline_variant)
                    : "transparent"

                TextInput {
                    id: typedInput

                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    visible: root.typing
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.typed
                    color: Theme.on_surface
                    font {
                        family: Layout.fontSans
                        pixelSize: 13
                    }

                    onTextChanged: {
                        root.typed = text;
                        root.setCurrent(text);
                    }
                }
            }

            Flickable {
                id: gridFlick

                width: parent.width
                height: Math.max(96, body.height
                    - titleText.implicitHeight
                    - comboRow.implicitHeight
                    - previewRect.height
                    - modRow.implicitHeight
                    - typedRect.height
                    - buttonRow.height
                    - body.spacing * 6)
                clip: true
                contentHeight: keysCol.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ThemedScrollBar {}

                Column {
                    id: keysCol

                    width: gridFlick.width
                    spacing: 10

                    Repeater {
                        model: root.typing ? [] : Keybinds.keyGroups

                        delegate: Column {
                            required property var modelData

                            width: keysCol.width
                            spacing: 6

                            Text {
                                width: parent.width
                                text: modelData.title
                                color: Theme.on_surface_variant
                                font {
                                    family: Layout.fontSans
                                    pixelSize: 11
                                }
                            }

                            Flow {
                                width: parent.width
                                spacing: 6

                                Repeater {
                                    model: modelData.keys

                                    delegate: Rectangle {
                                        id: keyBtn

                                        required property string modelData

                                        readonly property bool selected: Keybinds.partsOf(
                                            root.current).key === modelData

                                        width: keyLabel.implicitWidth + 22
                                        height: 32
                                        radius: 10
                                        color: keyBtn.selected
                                            ? Theme.primary
                                            : Theme.surface_container_highest
                                        border.width: 1
                                        border.color: keyBtn.selected
                                            ? Theme.primary
                                            : Theme.outline_variant

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 110
                                            }
                                        }

                                        Text {
                                            id: keyLabel
                                            anchors.centerIn: parent
                                            text: keyBtn.modelData
                                            color: keyBtn.selected
                                                ? Theme.on_primary
                                                : Theme.on_surface_variant
                                            font {
                                                family: Layout.fontSans
                                                pixelSize: 12
                                                weight: keyBtn.selected
                                                    ? Font.Medium
                                                    : Font.Normal
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.chooseKey(keyBtn.modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Row {
                id: buttonRow

                width: parent.width
                spacing: 10

                Item {
                    width: parent.width - 200
                    height: 1
                }

                Rectangle {
                    height: 40
                    width: 90
                    radius: 20
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.outline_variant

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: Theme.on_surface_variant
                        font {
                            family: Layout.fontSans
                            pixelSize: 13
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.close();
                            root.dismissed();
                        }
                    }
                }

                Rectangle {
                    height: 40
                    width: 100
                    radius: 20
                    color: applyHover.containsMouse ? Theme.primary_container : Theme.primary

                    Text {
                        anchors.centerIn: parent
                        text: "Apply"
                        color: Theme.on_primary
                        font {
                            family: Layout.fontSans
                            pixelSize: 13
                            weight: Font.Medium
                        }
                    }

                    MouseArea {
                        id: applyHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const text = Keybinds.joinList(root.combos);
                            if (text.length === 0)
                                return;
                            root.close();
                            root.applied(text);
                        }
                    }
                }
            }
        }
    }
}