pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import qs.services

Singleton {
    id: root

    readonly property bool caffeine: !!SettingsStore.get("caffeine")
    property real caffeineSinceMs: 0
    readonly property string activeSince: {
        if (!caffeine || caffeineSinceMs === 0)
            return "";
        const mins = Math.floor((Date.now() - caffeineSinceMs) / 60000);
        if (mins < 1)
            return "just now";
        const h = Math.floor(mins / 60);
        return h > 0 ? h + "h " + (mins % 60) + "m" : mins + "m";
    }

    readonly property int lockAfterMin: Number(SettingsStore.get("lockAfterMin") ?? 15)
    readonly property int screenOffAfterMin: Number(SettingsStore.get("screenOffAfterMin") ?? 10)
    readonly property int suspendAfterMin: Number(SettingsStore.get("suspendAfterMin") ?? 0)

    readonly property bool screenOff: false

    function setCaffeine(enabled) {
        SettingsStore.set("caffeine", !!enabled);
        if (enabled) {
            root.caffeineSinceMs = Date.now();
            caffeineStart.running = true;
        } else {
            root.caffeineSinceMs = 0;
            caffeineStop.running = true;
            if (root.screenOff)
                root.setScreenOff(false);
        }
        Toaster.toast(enabled ? "Caffeine on" : "Caffeine off",
                      enabled ? "Auto-lock and screen blanking are paused" : "Auto-lock and screen blanking are back",
                      "local_cafe",
                      enabled ? Toaster.warning : Toaster.info);
    }

    function toggleCaffeine() {
        root.setCaffeine(!root.caffeine);
    }

    function setScreenOff(off) {
        if (root.screenOff === off)
            return;
        dpmsProc.command = ["hyprctl", "dispatch", "dpms", off ? "off" : "on"];
        dpmsProc.running = true;
        root.screenOff = off;
    }

    Process {
        id: dpmsProc
    }

    PanelWindow {
        id: anchorWindow
        implicitWidth: 1
        implicitHeight: 1
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "idle_inhibitor_anchor"
        anchors { bottom: true; right: true }
        visible: root.caffeine
        mask: Region {}

        IdleInhibitor {
            id: inhibitor
            enabled: root.caffeine
            window: anchorWindow
        }
    }

    Process {
        id: caffeineStart
        command: ["systemctl", "--user", "start", "lampshell-keep-awake.service"]
    }

    Process {
        id: caffeineStop
        command: ["systemctl", "--user", "stop", "lampshell-keep-awake.service"]
    }

    readonly property bool idleActionsEnabled: !root.caffeine

    SessionBackend {
        id: sessionBackend
    }

    IdleMonitor {
        id: lockMonitor
        timeout: root.lockAfterMin * 60
        enabled: root.lockAfterMin > 0 && root.idleActionsEnabled
        respectInhibitors: true
    }
    Connections {
        target: lockMonitor
        function onIsIdleChanged() {
            if (lockMonitor.isIdle)
                sessionBackend.request("lock");
        }
    }

    IdleMonitor {
        id: screenMonitor
        timeout: root.screenOffAfterMin * 60
        enabled: root.screenOffAfterMin > 0 && root.idleActionsEnabled
        respectInhibitors: true
    }
    Connections {
        target: screenMonitor
        function onIsIdleChanged() {
            if (screenMonitor.isIdle)
                root.setScreenOff(true);
        }
    }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (root.screenOff && String(event.name).startsWith("input"))
                root.setScreenOff(false);
        }
    }

    IdleMonitor {
        id: suspendMonitor
        timeout: root.suspendAfterMin * 60
        enabled: root.suspendAfterMin > 0 && root.idleActionsEnabled
        respectInhibitors: true
    }
    Connections {
        target: suspendMonitor
        function onIsIdleChanged() {
            if (!suspendMonitor.isIdle)
                return;
            sessionBackend.request("lock");
            suspendProc.running = true;
        }
    }
    Process {
        id: suspendProc
        command: ["systemctl", "suspend"]
        running: false
    }

    Connections {
        target: SettingsStore
        function onLoadedChanged() {
            if (!SettingsStore.loaded || !root.caffeine)
                return;
            caffeineSinceMs = Date.now();
            caffeineStart.running = true;
        }
    }

    IpcHandler {
        target: "idle"

        function isCaffeineEnabled(): bool {
            return root.caffeine;
        }

        function enableCaffeine(): void {
            root.setCaffeine(true);
        }

        function disableCaffeine(): void {
            root.setCaffeine(false);
        }

        function toggleCaffeine(): void {
            root.toggleCaffeine();
        }

        function activeSince(): string {
            return root.activeSince;
        }

        function isScreenOff(): bool {
            return root.screenOff;
        }

        function screenOn(): void {
            root.setScreenOff(false);
        }

        function debugState(): string {
            return [
                "caffeine=" + root.caffeine,
                "lockAfterMin=" + root.lockAfterMin,
                "screenOffAfterMin=" + root.screenOffAfterMin,
                "lockTimeout=" + lockMonitor.timeout,
                "lockEnabled=" + lockMonitor.enabled,
                "lockIdle=" + lockMonitor.isIdle,
                "screenTimeout=" + screenMonitor.timeout,
                "screenEnabled=" + screenMonitor.enabled,
                "screenIdle=" + screenMonitor.isIdle
            ].join("\n");
        }
    }
}