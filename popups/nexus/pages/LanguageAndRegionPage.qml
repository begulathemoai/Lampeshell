import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme
import qs.services
import qs.popups.settings
import qs.popups.nexus
import qs.popups.nexus.common

PageBase {
    id: root

    title: "Language & region"
    description: "Locale, formats and timezone"

    property bool timezoneDialogOpen: false
    property bool localeDialogOpen: false
    property var timeZones: [{ label: "System default", key: "" }]
    property var locales: [{ label: "System default", key: "" }]

    readonly property string selectedTimeZone: String(SettingsStore.values.timeZone || "")
    readonly property string selectedLocale: String(SettingsStore.values.locale || "")
    readonly property string timeZoneLabel: selectedTimeZone.length > 0
        ? selectedTimeZone
        : "System default"
    readonly property string localeLabel: selectedLocale.length > 0
        ? selectedLocale
        : "System default (" + Qt.locale().name + ")"

    Process {
        id: timezoneProc
        command: ["timedatectl", "list-timezones"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const zones = text.split("\n")
                    .map(zone => zone.trim())
                    .filter(zone => zone.length > 0);
                if (zones.length > 0)
                    root.timeZones = [{ label: "System default", key: "" }]
                        .concat(zones.map(zone => ({ label: zone, key: zone })));
            }
        }
    }

    Process {
        id: localeProc
        command: ["locale", "-a"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const names = text.split("\n")
                    .map(name => name.trim())
                    .filter(name => name.length > 0);
                if (names.length > 0)
                    root.locales = [{ label: "System default", key: "" }]
                        .concat(names.map(name => ({ label: name, key: name })));
            }
        }
    }

    SettingsGroup {
        title: "Clock"
        description: "Choose the format, locale and timezone used by the bar and calendar."

        ToggleRow {
            icon: "schedule"
            label: "24-hour clock"
            description: "Use 00:00–23:59 instead of AM/PM"
            checked: Time.use24Hour
            onToggled: checked => SettingsStore.set("use24Hour", checked)
        }

        SettingsRow {
            icon: "language"
            label: "Locale"
            description: root.localeLabel
            onClicked: root.localeDialogOpen = true
        }

        SettingsRow {
            icon: "public"
            label: "Timezone"
            description: root.timeZoneLabel
            onClicked: root.timezoneDialogOpen = true
        }
    }

    overlay: Item {
        anchors.fill: parent

        ChoiceDialog {
            anchors.fill: parent
            open: root.localeDialogOpen
            searchable: true
            title: "Locale"
            model: root.locales
            current: root.selectedLocale
            onDismissed: root.localeDialogOpen = false
            onChosen: function(key) {
                SettingsStore.set("locale", key);
                root.localeDialogOpen = false;
            }
        }

        ChoiceDialog {
            anchors.fill: parent
            open: root.timezoneDialogOpen
            searchable: true
            title: "Timezone"
            model: root.timeZones
            current: root.selectedTimeZone
            onDismissed: root.timezoneDialogOpen = false
            onChosen: function(key) {
                SettingsStore.set("timeZone", key);
                root.timezoneDialogOpen = false;
            }
        }
    }
}
