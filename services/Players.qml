pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var players: Mpris.players.values
    readonly property var active: players.length > 0 ? players[0] : null

    readonly property string activeTitle: active?.trackTitle ?? ""
    readonly property string activeArtist: active?.trackArtist ?? ""
    readonly property string activeAlbum: active?.trackAlbum ?? ""
    readonly property string activeIdentity: active?.identity ?? ""
    readonly property bool activeIsPlaying: active?.isPlaying ?? false

    function _play() { if (active) active.play(); }
    function _pause() { if (active) active.pause(); }
    function _toggle() { if (active) active.togglePlaying(); }
    function _next() { if (active) active.next(); }
    function _previous() { if (active) active.previous(); }
    function _stop() { if (active) active.stop(); }

    IpcHandler {
        target: "mpris"

        function play(): void { root._play(); }
        function pause(): void { root._pause(); }
        function toggle(): void { root._toggle(); }
        function next(): void { root._next(); }
        function previous(): void { root._previous(); }
        function stop(): void { root._stop(); }

        function list(): string {
            return root.players.map(p => p.identity).join("\n");
        }

        function getActive(prop: string): string {
            if (!root.active)
                return "";
            switch (prop) {
                case "title": return root.active.trackTitle ?? "";
                case "artist": return root.active.trackArtist ?? "";
                case "album": return root.active.trackAlbum ?? "";
                case "identity": return root.active.identity;
                case "isPlaying": return root.active.isPlaying ? "true" : "false";
                default: return "";
            }
        }
    }
}
