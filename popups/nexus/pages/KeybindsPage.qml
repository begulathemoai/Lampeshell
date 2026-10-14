import QtQuick
import qs.theme
import qs.services
import qs.popups.settings
import qs.popups.nexus
import qs.popups.nexus.common

PageBase {
    id: root

    title: "Keybinds & Shortcuts"
    description: "Hyprland keybinds, written straight to your config"

    property var drafts: ({})

    function textFor(key) {
        if (Object.prototype.hasOwnProperty.call(root.drafts, key))
            return root.drafts[key];
        return Keybinds.textFor(key);
    }

    function clashKeys() {
        const seen = {};
        const clashes = {};

        for (const key of Keybinds.order) {
            for (const combo of Keybinds.splitList(root.textFor(key))) {
                const norm = Keybinds.normalise(combo);
                if (norm.length === 0)
                    continue;
                if (seen[norm] === undefined)
                    seen[norm] = key;
                else {
                    clashes[key] = true;
                    clashes[seen[norm]] = true;
                }
            }
        }

        return clashes;
    }

    readonly property var clashes: root.clashKeys()

    function markDraft(key, text) {
        const next = Object.assign({}, root.drafts);
        next[key] = text;
        root.drafts = next;
    }

    function applyAll() {
        const keys = Object.keys(root.drafts);
        for (const key of keys) {
            const binds = String(root.drafts[key]).split(",").map(s => s.trim()).filter(s => s.length > 0);
            for (const bind of binds) {
                if (!Keybinds.isSafeBind(bind)) {
                    root.drafts = ({});
                    Toaster.toastError("Keybind not saved", "Invalid characters in: " + bind, "error");
                    return;
                }
            }
        }
        for (const key of keys)
            Keybinds.setBind(key, root.drafts[key]);
        Keybinds.save();
        root.drafts = ({});
        Toaster.toastSuccess("Keybinds saved", "Hyprland configuration reloaded", "keyboard");
    }

    function revertAll() {
        root.drafts = ({});
        Keybinds.revert();
        Toaster.toastInfo("Keybinds reverted", "Reloaded from disk", "undo");
    }

    overlay: Item {
        anchors.fill: parent

        KeybindPickerSheet {
            id: picker

            anchors.fill: parent

            onApplied: text => {
                root.markDraft(picker.bindKey, text);
                root.nState.overlayOpen = false;
            }

            onDismissed: root.nState.overlayOpen = false
        }
    }

    SettingsCard {
        title: "Your keybinds"
        subtitle: "Click a bind to change it. Edits are written to " + Keybinds.path + " and Hyprland is reloaded."

        Row {
            spacing: 10

            ActionButton {
                text: "Save and reload"
                icon: "save"
                onTriggered: root.applyAll()
            }

            ActionButton {
                text: "Revert"
                icon: "undo"
                onTriggered: root.revertAll()
            }
        }

        Text {
            width: parent.width
            visible: Object.keys(root.drafts).length > 0
            text: Object.keys(root.drafts).length + " unsaved change(s)"
            color: Theme.primary
            font {
                family: Layout.fontSans
                pixelSize: 12
                weight: Font.Medium
            }
        }
    }

    Text {
        width: parent.width
        visible: Keybinds.lastError.length > 0
        text: Keybinds.lastError
        wrapMode: Text.WordWrap
        color: Theme.critical
        font {
            family: Layout.fontSans
            pixelSize: 12
        }
    }

    SettingsGroup {
        title: "How binds are written"
        description: "Click any bind to build it from modifier and key chips. Separate several keybinds for one action with the plus another chip."

        InfoRow {
            label: "Config file"
            value: Keybinds.path
        }
        InfoRow {
            label: "Keybinds found"
            value: String(Keybinds.order.length)
        }
    }

    Rectangle {
        width: parent.width
        height: clashText.implicitHeight + 24
        radius: 20
        visible: Object.keys(root.clashes).length > 0
        color: Qt.rgba(Theme.critical.r, Theme.critical.g, Theme.critical.b, 0.12)
        border.width: 1
        border.color: Theme.critical

        Text {
            id: clashText

            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: Object.keys(root.clashes).length + " action(s) share the same combination. "
                + "Hyprland uses the last one, so the others will never fire."
            color: Theme.critical
            wrapMode: Text.WordWrap
            font {
                family: Layout.fontSans
                pixelSize: 12
            }
        }
    }

    Repeater {
        model: Keybinds.visibleGroups()

        delegate: SettingsGroup {
            required property var modelData

            readonly property var bindKeys: modelData.keys

            title: modelData.title

            Repeater {
                id: inner
                model: bindKeys

                delegate: KeybindRow {
                    required property var modelData
                    required property int index

                    label: Keybinds.labelFor(modelData)
                    bindKey: modelData
                    bindText: root.textFor(modelData)
                    clashes: Object.prototype.hasOwnProperty.call(root.clashes, modelData) ? ["1"] : []
                    isFirst: index === 0
                    isLast: index === inner.count - 1
                    onPicked: {
                        root.nState.overlayOpen = true;
                        picker.openFor(modelData, Keybinds.labelFor(modelData), root.textFor(modelData));
                    }
                }
            }
        }
    }
}
