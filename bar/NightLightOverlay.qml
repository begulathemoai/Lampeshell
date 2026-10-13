import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services

// Last-resort night light, for a display that accepts no colour write at all:
// a proprietary driver exposing no CRTC gamma, a monitor whose DDC colour
// controls have gone read-only, a panel with nothing but brightness.
//
// It cannot set a white point. An alpha overlay composites towards a colour
// but never reaches it, so this is a filter over the screen rather than a
// colour temperature, and the status row says exactly that instead of
// quoting a Kelvin value it has not achieved.
//
// Hyprland's overlay layer is drawn above every normal window, so this covers
// applications as well as the shell. It does not cover anything scanning out
// on its own DRM plane, which is how games and video often reach the monitor.
Variants {
    id: root
    model: Quickshell.screens

    delegate: PanelWindow {
        required property var modelData
        screen: modelData

        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-nightlight"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        visible: NightLight.overlayActive

        // A filter that swallowed clicks would break the desktop it is
        // supposed to be protecting. Xor inverts the full-window rectangle
        // into an empty input region, which makes Quickshell mark the surface
        // transparent for input - the same trick the chrome uses.
        mask: Region {
            item: tint
            intersection: Intersection.Xor
        }

        Rectangle {
            id: tint

            anchors.fill: parent
            color: NightLight.overlayColor
            opacity: NightLight.overlayAlpha
        }
    }
}