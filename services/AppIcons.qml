pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var cache: ({})
    property var queue: []

    property bool busy: false
    property string currentKey: ""
    property string currentApp: ""

    signal lookupRequested(string key, string appName)

    onLookupRequested: (key, appName) => enqueue(key, appName)

    readonly property string script: "name=$1\n[ -z \"$name\" ] || exit 0\n"
        + "match=$(grep -rli -m1 -x -F \"Name=$name\" \"$HOME/.local/share/applications\" /usr/share/applications 2>/dev/null | head -1)\n"
        + "[ -n \"$match\" ] || exit 0\n"
        + "icon=$(grep -m1 -E '^Icon=' \"$match\" | cut -d= -f2-)\n"
        + "stem=$(basename \"$match\" .desktop)\n"
        + "printf '%s\\n%s\\n%s\\n' \"$icon\" \"$stem\" \"$name\"\n"

    function iconFor(appName, appIcon) {
        if (appIcon) {
            const direct = resolve(appIcon);
            if (direct)
                return direct;
        }
        if (!appName)
            return "";
        const key = appName.toLowerCase();
        if (cache[key] !== undefined)
            return cache[key];
        lookupRequested(key, appName);
        return "";
    }

    function resolve(icon) {
        if (!icon)
            return "";
        if (icon.startsWith("/"))
            return "file://" + icon;
        if (icon.startsWith("file://") || icon.startsWith("http"))
            return icon;
        return Quickshell.iconPath(icon, true) || "";
    }

    function enqueue(key, appName) {
        if (!queue.some(entry => entry.key === key))
            queue.push({ key: key, appName: appName });
        if (!busy)
            runNext();
    }

    function runNext() {
        const entry = queue.shift();
        if (!entry) {
            busy = false;
            return;
        }
        busy = true;
        currentKey = entry.key;
        currentApp = entry.appName;
        lookup.running = true;
    }

    function applyOutput(text) {
        const candidates = text.split("\n").map(s => s.trim()).filter(s => s.length > 0);

        let found = "";
        for (const candidate of candidates) {
            const url = resolve(candidate);
            if (url) {
                found = url;
                break;
            }
        }

        cache = Object.assign({}, cache, { [currentKey]: found });
        busy = false;
        runNext();
    }

    Process {
        id: lookup

        command: ["bash", "-c", root.script, "_", root.currentApp]

        stdout: StdioCollector {
            onStreamFinished: root.applyOutput(this.text)
        }
    }
}