pragma Singleton

import QtQuick

QtObject {
    property int topBarHeight: 65         // 50 base * 1.3 uiScale
    property int sideBarWidth: 78         // 10 base * 1.3 uiScale - 1.3 makes the sidebar a usable dock on 4K
    property int rightBarWidth: 10        // the right bar stays a hairline bezel; only the left bar is a dock
    property int bottomBarHeight: 13     // 10 base * 1.3 uiScale

    property int cornerRadius: 20

    property real uiScale: 1.3

    function s(n) { return Math.round(n * uiScale) }
    function ts(n) { return Math.max(14, Math.round(n * uiScale)) }

    property string fontSans: "Google Sans"
    property string fontIcons: "Material Symbols Rounded"

    property string targetMonitor: ""
}
