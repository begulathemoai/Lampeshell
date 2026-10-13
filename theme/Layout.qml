pragma Singleton

import QtQuick

QtObject {
    property int topBarHeight: s(50)
    property int sideBarWidth: 10         // left bezel frame (the old dock is gone)
    property int rightBarWidth: 10        // the right bar stays a hairline bezel
    property int bottomBarHeight: s(10)

    property int cornerRadius: 20

    property int panelRadius: 28

    // Caelestia sizes everything in logical pixels and lets Qt's per-output
    // devicePixelRatio handle HiDPI - it has no hand-tuned multiplier. Our
    // old 1.3 was multiplied on top of that DPR, so a 2x screen rendered the
    // whole shell at 2.6x. Keep `scale` as a knob, but default it to 1.
    property real uiScale: 1.0

    function s(n) { return Math.round(n * uiScale) }
    function ts(n) { return Math.max(14, Math.round(n * uiScale)) }

    property string fontSans: "Google Sans"
    property string fontIcons: "Material Symbols Rounded"

    property string targetMonitor: ""
}
