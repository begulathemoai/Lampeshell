pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string path: (Quickshell.env("HOME") || "") + "/.config/hypr/variables.lua"

    property var bindings: ({})
    property var order: []
    property bool loaded: false
    property string lastError: ""

    property string original: ""

    readonly property var groups: [
        {
            title: "Launcher and panels",
            keys: ["kbLauncher", "kbShowPanels", "kbShowSidebar", "kbSession", "kbLock", "kbRestoreLock", "kbSleep", "kbClearNotifs", "kbClipboard", "kbClipboardDel", "kbClipboardPasteLatest", "kbEmoji"]
        },
        {
            title: "Workspaces",
            keys: ["kbGoToWs", "kbGoToWsGroup", "kbMoveWinToWs", "kbMoveWinToWsGroup", "kbNextWs", "kbPrevWs", "kbNextWsGroup", "kbPrevWsGroup", "kbMoveWinToWsNext", "kbMoveWinToWsPrev", "kbMoveWinToWsSpecial", "kbMoveWinFromWsSpecial", "kbSpecialWs", "kbSystemMonitorWs", "kbMusicWs", "kbCommunicationWs", "kbTodoWs"]
        },
        {
            title: "Windows",
            keys: ["kbWindowCycleNext", "kbWindowCyclePrev", "kbWindowGroupCycleNext", "kbWindowGroupCyclePrev", "kbToggleGroup", "kbGroupLockActive", "kbUngroup", "kbMoveWindow", "kbResizeWindow", "kbCenterWindow", "kbNormalizeWindow", "kbWindowPip", "kbPinWindow", "kbWindowFullscreen", "kbWindowBorderedFullscreen", "kbToggleWindowFloating", "kbCloseWindow", "kbWindowDecreaseWidth", "kbWindowIncreaseWidth", "kbWindowDecreaseHeight", "kbWindowIncreaseHeight"]
        },
        {
            title: "Apps",
            keys: ["kbTerminal", "kbBrowser", "kbEditor", "kbFileExplorer", "kbAudioSettings"]
        },
        {
            title: "Utilities and media",
            keys: ["kbScreenshot", "kbScreenshotFreeze", "kbScreenshotRegion", "kbRecord", "kbRecordSound", "kbRecordRegion", "kbColorPicker", "kbMediaToggle", "kbMediaNext", "kbMediaPrev", "kbMediaStop", "kbVolumeMute"]
        }
    ]

    readonly property var labels: ({
        kbLauncher: "Open launcher",
        kbShowPanels: "Quick settings panel",
        kbShowSidebar: "Sidebar",
        kbSession: "Session menu",
        kbLock: "Lock screen",
        kbRestoreLock: "Restore lock",
        kbSleep: "Sleep",
        kbClearNotifs: "Clear notifications",
        kbClipboard: "Clipboard manager",
        kbClipboardDel: "Delete clipboard entry",
        kbClipboardPasteLatest: "Paste latest clipboard entry",
        kbEmoji: "Emoji picker",
        kbGoToWs: "Go to workspace (modifier)",
        kbGoToWsGroup: "Go to workspace group (modifier)",
        kbMoveWinToWs: "Move window to workspace (modifier)",
        kbMoveWinToWsGroup: "Move window to group (modifier)",
        kbNextWs: "Next workspace",
        kbPrevWs: "Previous workspace",
        kbNextWsGroup: "Next workspace group",
        kbPrevWsGroup: "Previous workspace group",
        kbMoveWinToWsNext: "Move window to next workspace",
        kbMoveWinToWsPrev: "Move window to previous workspace",
        kbMoveWinToWsSpecial: "Move window to special workspace",
        kbMoveWinFromWsSpecial: "Move window out of special workspace",
        kbSpecialWs: "Toggle special workspace",
        kbSystemMonitorWs: "System monitor workspace",
        kbMusicWs: "Music workspace",
        kbCommunicationWs: "Communication workspace",
        kbTodoWs: "Todo workspace",
        kbWindowCycleNext: "Cycle window",
        kbWindowCyclePrev: "Cycle window backwards",
        kbWindowGroupCycleNext: "Cycle window group",
        kbWindowGroupCyclePrev: "Cycle window group backwards",
        kbToggleGroup: "Toggle window group",
        kbGroupLockActive: "Lock active group",
        kbUngroup: "Ungroup window",
        kbMoveWindow: "Move window with mouse",
        kbResizeWindow: "Resize window with mouse",
        kbCenterWindow: "Centre window",
        kbNormalizeWindow: "Normalise window",
        kbWindowPip: "Picture in picture",
        kbPinWindow: "Pin window",
        kbWindowFullscreen: "Fullscreen",
        kbWindowBorderedFullscreen: "Maximised fullscreen",
        kbToggleWindowFloating: "Toggle floating",
        kbCloseWindow: "Close window",
        kbWindowDecreaseWidth: "Decrease width",
        kbWindowIncreaseWidth: "Increase width",
        kbWindowDecreaseHeight: "Decrease height",
        kbWindowIncreaseHeight: "Increase height",
        kbTerminal: "Terminal",
        kbBrowser: "Browser",
        kbEditor: "Editor",
        kbFileExplorer: "File manager",
        kbAudioSettings: "Audio settings",
        kbScreenshot: "Screenshot",
        kbScreenshotFreeze: "Screenshot with frozen screen",
        kbScreenshotRegion: "Screenshot region",
        kbRecord: "Record screen",
        kbRecordSound: "Record screen with audio",
        kbRecordRegion: "Record region",
        kbColorPicker: "Colour picker",
        kbMediaToggle: "Play or pause",
        kbMediaNext: "Next track",
        kbMediaPrev: "Previous track",
        kbMediaStop: "Stop playback",
        kbVolumeMute: "Mute audio"
    })

    FileView {
        id: file
        path: root.path
        printErrors: false
        watchChanges: true

        onLoaded: root.parse(text())

        onLoadFailed: err => {
            root.lastError = err === FileViewError.FileNotFound
                ? "Keybinds file not found at " + root.path
                : "Could not read the keybinds file";
            root.loaded = true;
        }

        onFileChanged: reload()
    }

    Process {
        id: reloadProc
    }

    readonly property var lineRe: /^(\s*)([A-Za-z_][A-Za-z0-9_]*)(\s*=\s*)(.+?)(,?)(\s*)$/

    function parse(text) {
        const result = {};
        const order = [];
        const lines = String(text).split("\n");

        for (const line of lines) {
            const m = line.match(root.lineRe);
            if (!m)
                continue;
            if (m[2].indexOf("kb") !== 0)
                continue;
            const binds = root.extractBinds(m[4]);
            if (binds.length === 0)
                continue;
            result[m[2]] = binds;
            order.push(m[2]);
        }

        root.bindings = result;
        root.order = order;
        root.original = String(text);
        root.lastError = "";
        root.loaded = true;
    }

    function extractBinds(value) {
        const binds = [];
        const strRe = /"([^"]*)"|'([^']*)'/g;
        let sm;
        while ((sm = strRe.exec(value)) !== null)
            binds.push(sm[1] !== undefined ? sm[1] : sm[2]);
        return binds;
    }

    function textFor(key) {
        const binds = root.bindings[key];
        if (!binds || binds.length === 0)
            return "";
        return binds.join(", ");
    }

    function labelFor(key) {
        return root.labels[key] ?? key;
    }

    function groupKeys(group) {
        const seen = {};
        const result = [];
        for (const key of group.keys) {
            if (!root.bindings[key] || seen[key])
                continue;
            seen[key] = true;
            result.push(key);
        }
        return result;
    }

    function ungroupedKeys() {
        const seen = {};
        for (const group of root.groups)
            for (const key of group.keys)
                seen[key] = true;
        return root.order.filter(k => !seen[k]);
    }

    function visibleGroups() {
        const result = [];
        for (const group of root.groups) {
            const keys = root.groupKeys(group);
            if (keys.length > 0)
                result.push({ title: group.title, keys: keys });
        }
        const other = root.ungroupedKeys();
        if (other.length > 0)
            result.push({ title: "Other binds", keys: other });
        return result;
    }

    function isSafeBind(bind) {
        if (!bind || bind.length === 0)
            return false;
        return !/["'\\{}#;\n\r]/.test(bind);
    }

    function setBind(key, text) {
        const binds = String(text).split(",").map(s => s.trim()).filter(s => s.length > 0);
        if (binds.length === 0)
            return false;
        for (const bind of binds) {
            if (!root.isSafeBind(bind)) {
                root.lastError = "Invalid characters in keybind: " + bind;
                return false;
            }
        }
        const next = Object.assign({}, root.bindings);
        next[key] = binds;
        root.bindings = next;
        root.lastError = "";
        return true;
    }

    function buildText() {
        const lines = String(root.original).split("\n");

        for (let i = 0; i < lines.length; i++) {
            const m = lines[i].match(root.lineRe);
            if (!m || m[2].indexOf("kb") !== 0)
                continue;
            const binds = root.bindings[m[2]];
            if (!binds || binds.length === 0)
                continue;
            let value;
            if (binds.length === 1)
                value = '"' + binds[0] + '"';
            else
                value = "{ " + binds.map(b => '"' + b + '"').join(", ") + " }";
            lines[i] = m[1] + m[2] + m[3] + value + m[5];
        }

        return lines.join("\n");
    }

    function reload() {
        file.reload();
    }

    function isDirty() {
        return root.buildText() !== root.original;
    }

    function save() {
        const text = root.buildText();
        file.setText(text);
        root.original = text;
        reloadProc.command = ["hyprctl", "reload", "config-only"];
        reloadProc.running = true;
    }

    function revert() {
        file.reload();
    }

    IpcHandler {
        target: "keybinds"

        function reload(): void {
            root.file.reload();
        }

        function list(): string {
            return root.order.map(k => k + " = " + root.textFor(k)).join("\n");
        }
    }
}
