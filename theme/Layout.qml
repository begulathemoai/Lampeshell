pragma Singleton

import QtQuick

QtObject {
    // Where the content bar lives. Bound from SettingsStore by shell.qml.
    property string barPosition: "top"

    readonly property bool barHorizontal: barPosition === "top" || barPosition === "bottom"
    readonly property bool barVertical: barPosition === "left" || barPosition === "right"

    readonly property bool barAtTop: barPosition === "top"
    readonly property bool barAtBottom: barPosition === "bottom"
    readonly property bool barAtLeft: barPosition === "left"
    readonly property bool barAtRight: barPosition === "right"

    // Thickness of the content bar and of the decorative frame on the other edges.
    property int barThickness: s(50)
    property int frameThickness: s(10)

    property int topBarHeight: barPosition === "top" ? barThickness : frameThickness
    property int sideBarWidth: barPosition === "left" ? barThickness : frameThickness
    property int rightBarWidth: barPosition === "right" ? barThickness : frameThickness
    property int bottomBarHeight: barPosition === "bottom" ? barThickness : frameThickness

    property int cornerRadius: 20

    property int panelRadius: 28

    // Connected-card metrics (Metrolist-KMP settings groups): a run of rows shares one card, separated by a small gap.
    property int connectedOuterRadius: 20
    property int connectedInnerRadius: 5
    property int connectedSpacing: 4
    property int rowMinHeight: 72

    property real uiScale: 1.0

    function s(n) { return Math.round(n * uiScale) }
    function ts(n) { return Math.max(14, Math.round(n * uiScale)) }

    property string fontSans: "Google Sans"
    property string fontIcons: "Material Symbols Rounded"

    property string targetMonitor: ""
}
