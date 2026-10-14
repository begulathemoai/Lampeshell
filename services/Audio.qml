pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var allNodes: Pipewire.nodes?.values ?? []
    readonly property var activeSink: Pipewire.defaultAudioSink
    readonly property var activeSource: Pipewire.defaultAudioSource

    function nodeKind(node) {
        return PwNodeType.toString(node.type);
    }

    readonly property var sinks: root.allNodes.filter(n => root.nodeKind(n) === "AudioSink")
    readonly property var sources: root.allNodes.filter(n => root.nodeKind(n) === "AudioSource")
    readonly property var streams: root.allNodes.filter(n => n.isStream && n.isSink)

    readonly property var audibleStreams: root.streams.filter(s => (s.audio?.volume ?? 0) > 0.001 || s.audio?.muted === false)

    function setSink(node) {
        if (!node)
            return;
        Pipewire.preferredDefaultAudioSink = node;
        Pipewire.defaultAudioSink = node;
        Toaster.toast("Output switched", displayName(node), iconForSink(node), Toaster.success);
    }

    function setSource(node) {
        if (!node)
            return;
        Pipewire.preferredDefaultAudioSource = node;
        Pipewire.defaultAudioSource = node;
        Toaster.toast("Input switched", displayName(node), iconForSource(node), Toaster.success);
    }

    function cycleSink() {
        const list = root.sinks;
        if (list.length < 2)
            return -1;
        const idx = list.findIndex(n => n === root.activeSink);
        const next = list[(idx + 1) % list.length];
        root.setSink(next);
        return list.indexOf(next);
    }

    function displayName(node) {
        if (!node)
            return "";
        return node.description || node.nickname || node.name || "";
    }

    function setStreamVolume(node, fraction) {
        if (!node || !node.audio)
            return;
        node.audio.volume = fraction;
        node.audio.muted = fraction <= 0.0;
    }

    function toggleStreamMute(node) {
        if (node && node.audio)
            node.audio.muted = !node.audio.muted;
    }

    function iconForSink(node) {
        const desc = (root.displayName(node) + " " + ((node && node.nickname) || "")).toLowerCase();
        if (/hdmi|display|monitor|\btv\b|benq/.test(desc))
            return "tv";
        if (/bluetooth|\bbt\b|headset|headphone|airpod|buds|tune/.test(desc))
            return "headphones";
        return "speaker";
    }

    function iconForSource(node) {
        const desc = (root.displayName(node) + " " + ((node && node.nickname) || "")).toLowerCase();
        if (/camera|webcam/.test(desc))
            return "videocam";
        if (/headset|headphone|airpod|buds|tune/.test(desc))
            return "headset_mic";
        return "mic";
    }

    function iconForStream(node) {
        const desc = (root.displayName(node) + " " + ((node && node.nickname) || "")).toLowerCase();
        if (/chrom|firefox|brave|vivaldi|opera|edge/.test(desc))
            return "language";
        if (/steam|game|lutris|heroic|wine/.test(desc))
            return "sports_esports";
        if (/spotify|music|rhythm|vlc/.test(desc))
            return "music_note";
        if (/discord|legcord|element|signal|telegram/.test(desc))
            return "forum";
        return "graphic_eq";
    }

    IpcHandler {
        target: "audio"

        function listSinks(): string {
            return root.sinks.map((n, i) => i + ": " + root.displayName(n)).join("\n");
        }

        function listSources(): string {
            return root.sources.map((n, i) => i + ": " + root.displayName(n)).join("\n");
        }

        function listStreams(): string {
            return root.streams.map((n, i) => i + ": " + root.displayName(n)).join("\n");
        }

        function currentSink(): string {
            return root.displayName(root.activeSink);
        }

        function currentSource(): string {
            return root.displayName(root.activeSource);
        }

        function cycleOutput(): void {
            root.cycleSink();
        }

        function setSink(index: int): void {
            root.setSink(root.sinks[index]);
        }

        function setSource(index: int): void {
            root.setSource(root.sources[index]);
        }

        function setStreamVolume(index: int, percent: real): void {
            root.setStreamVolume(root.streams[index], percent / 100);
        }

        function toggleStreamMute(index: int): void {
            root.toggleStreamMute(root.streams[index]);
        }
    }
}