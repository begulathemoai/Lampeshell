import QtQuick
import qs.services
import qs.theme
import qs.popups.settings
import qs.popups.nexus
import qs.popups.nexus.common

PageBase {
    id: root

    title: "Theme targets"
    description: "Carry the palette into the apps you use"

    SettingsGroup {
        title: "Applications"
        description: "Lampshell rewrites colours in place. It never creates a file, and it leaves anything it does not recognise alone."

        Repeater {
            model: Targets.targets

            delegate: ToggleRow {
                required property var modelData

                label: modelData.label
                description: modelData.key === "hypr"
                    ? modelData.description
                    : (Targets.exists(modelData.key)
                        ? modelData.description
                        : modelData.description + " (no config file found)")
                enabled: modelData.key === "hypr" || Targets.exists(modelData.key)
                checked: SettingsStore.get("themeTarget" + modelData.key) === true

                onToggled: next => {
                    if (modelData.key !== "hypr" && !Targets.exists(modelData.key))
                        return;
                    SettingsStore.set("themeTarget" + modelData.key, next);
                }
            }
        }
    }

    SettingsCard {
        Column {
            width: parent.width
            spacing: 10

            Text {
                text: "How this works"
                color: Theme.on_surface
                font {
                    family: Layout.fontSans
                    pixelSize: 15
                }
            }

            Text {
                width: parent.width
                text: "An application target only updates when its config file already exists, so nothing is created in a config you never set up. The compositor border is set at runtime rather than written to a file. Turning one off leaves the last colours in place."
                color: Theme.on_surface_variant
                wrapMode: Text.WordWrap
                font {
                    family: Layout.fontSans
                    pixelSize: 13
                }
            }
        }
    }
}