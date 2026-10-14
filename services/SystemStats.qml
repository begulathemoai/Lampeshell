pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Lampshell.Services

Singleton {
    id: root

    property bool active: false

    ServiceRef { service: root.active ? Cpu : null }
    ServiceRef { service: root.active ? Memory : null }
    ServiceRef { service: root.active ? Storage : null }
    ServiceRef { service: root.active ? Gpu : null }
    ServiceRef { service: root.active ? NetworkUsage : null }

    property real cpu: Cpu.percentage * 100
    property string cpuName: Cpu.name
    property real cpuTemp: Cpu.temperature
    property bool hasCpuTemp: Cpu.temperature > 0

    property real memTotal: Memory.total * 1024
    property real memUsed: Memory.used * 1024
    property real memAvail: memTotal - memUsed
    property real swapTotal: 0
    property real swapUsed: 0

    property var primaryDisk: Storage.primaryDisk
    property real diskTotal: primaryDisk ? primaryDisk.total * 1024 : 0
    property real diskUsed: primaryDisk ? primaryDisk.used * 1024 : 0

    property real netRx: NetworkUsage.downloadSpeed
    property real netTx: NetworkUsage.uploadSpeed

    property real uptime: 0
    property real load1: 0
    property real load5: 0
    property real load15: 0

    property string gpuName: Gpu.name
    property bool hasGpu: Gpu.type !== Gpu.None
    property real gpuUsage: Gpu.percentage * 100
    property real gpuTemp: Gpu.temperature
    property bool hasGpuTemp: Gpu.temperature > 0
    property real gpuMemUsed: 0
    property real gpuMemTotal: 0

    readonly property real memFraction: memTotal > 0 ? memUsed / memTotal : 0
    readonly property real swapFraction: swapTotal > 0 ? swapUsed / swapTotal : 0
    readonly property real diskFraction: diskTotal > 0 ? diskUsed / diskTotal : 0
    readonly property real gpuMemFraction: gpuMemTotal > 0 ? gpuMemUsed / gpuMemTotal : 0

    function formatBytes(bytes, decimals) {
        if (!bytes || bytes < 1)
            return "0 B";
        const k = 1024;
        const units = ["B", "KB", "MB", "GB", "TB"];
        const i = Math.min(Math.floor(Math.log(bytes) / Math.log(k)), units.length - 1);
        const value = bytes / Math.pow(k, i);
        return value.toFixed(i === 0 ? 0 : (decimals ?? 1)) + " " + units[i];
    }

    function formatDuration(seconds) {
        const s = Math.floor(seconds);
        const d = Math.floor(s / 86400);
        const h = Math.floor((s % 86400) / 3600);
        const m = Math.floor((s % 3600) / 60);
        if (d > 0)
            return d + "d " + h + "h " + m + "m";
        if (h > 0)
            return h + "h " + m + "m";
        return m + "m";
    }

    FileView {
        id: uptimeView
        path: "/proc/uptime"
        blockLoading: true
        onTextChanged: root.uptime = parseFloat(text) || 0
    }

    FileView {
        id: loadView
        path: "/proc/loadavg"
        blockLoading: true
        onTextChanged: {
            const p = text().trim().split(/\s+/);
            root.load1 = parseFloat(p[0]) || 0;
            root.load5 = parseFloat(p[1]) || 0;
            root.load15 = parseFloat(p[2]) || 0;
        }
    }

    Timer {
        interval: 2500
        repeat: true
        running: root.active
        onTriggered: {
            uptimeView.reload();
            loadView.reload();
        }

        onRunningChanged: {
            if (running) {
                uptimeView.reload();
                loadView.reload();
            }
        }
    }
}
