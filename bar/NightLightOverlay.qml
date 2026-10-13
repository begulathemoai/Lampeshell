import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services

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