pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property bool use24Hour: SettingsStore.loaded
        && SettingsStore.values.use24Hour === true
    readonly property string configuredTimeZone: SettingsStore.loaded
        ? String(SettingsStore.values.timeZone || "")
        : ""
    readonly property string configuredLocale: SettingsStore.loaded
        ? String(SettingsStore.values.locale || "")
        : ""
    readonly property string timeZone: configuredTimeZone
    property date zoneDate: clock.date
    property string hour24: ""
    property string hour12: ""
    property string minute: ""
    property string period: ""
    property string dateSummary: ""
    property string weekday: ""
    property string longDate: ""
    readonly property date localDate: zoneDate
    readonly property int hourValue: localDate.getHours()
    readonly property string hourText: use24Hour ? hour24 : hour12.replace(/^0/, "")
    readonly property string minuteText: minute
    readonly property string periodText: period
    readonly property string time: {
        const value = hourText + ":" + minuteText
            + (use24Hour ? "" : " " + periodText);
        return " " + value + " • "
            + dateSummary + " ";
    }
    readonly property string weekdayDate: weekday
    readonly property int year: localDate.getFullYear()
    readonly property int month: localDate.getMonth()
    readonly property int day: localDate.getDate()

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Process {
        id: zoneProc
        command: root.dateCommand()
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.updateDate(text)
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: zoneProc.running = true
    }

    Connections {
        target: SettingsStore
        function onValuesChanged() {
            zoneProc.running = true;
        }
    }

    function updateDate(value) {
        const fields = value.trim().split("|");
        if (fields.length < 10)
            return;
        const numbers = fields.slice(0, 3).concat(fields.slice(7, 10)).map(Number);
        if (numbers.some(Number.isNaN))
            return;
        root.hour24 = fields[0];
        root.hour12 = fields[1];
        root.minute = fields[2];
        root.period = fields[3];
        root.dateSummary = fields[4];
        root.weekday = fields[5];
        root.longDate = fields[6];
        root.zoneDate = new Date(numbers[3], numbers[4] - 1, numbers[5], 0, 0, 0);
    }

    function dateCommand() {
        const args = [];
        if (timeZone.length > 0)
            args.push("TZ=" + timeZone);
        if (configuredLocale.length > 0)
            args.push("LC_TIME=" + configuredLocale);
        args.push("date", "+%H|%I|%M|%p|%a, %b %-d|%A|%B %-d, %Y|%Y|%-m|%-d");
        return args.length === 1 ? args : ["env"].concat(args);
    }
}
