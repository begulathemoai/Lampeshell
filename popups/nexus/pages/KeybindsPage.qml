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

    SettingsCard {
        title: "Your keybinds"
        subtitle: "Edits are written to " + Keybinds.path + " and Hyprland is reloaded."

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
        description: "Separate several keybinds for one action with commas, for example SUPER + K, CTRL + SUPER + K. Modifiers are SUPER, CTRL, ALT and SHIFT."

        InfoRow {
            label: "Config file"
            value: Keybinds.path
        }
        InfoRow {
            label: "Keybinds found"
            value: String(Keybinds.order.length)
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
                    bindText: Keybinds.textFor(modelData)
                    isFirst: index === 0
                    isLast: index === inner.count - 1
                    onEdited: text => root.markDraft(modelData, text)
                }
            }
        }
    }
}
