pragma Singleton

import QtQuick

QtObject {
    property int topBarHeight: s(50)
    property int sideBarWidth: 10
    property int rightBarWidth: 10
    property int bottomBarHeight: s(10)

    property int cornerRadius: 20

    property int panelRadius: 28

    property real uiScale: 1.0

    function s(n) { return Math.round(n * uiScale) }
    function ts(n) { return Math.max(14, Math.round(n * uiScale)) }

    property string fontSans: "Google Sans"
    property string fontIcons: "Material Symbols Rounded"

    property string targetMonitor: ""
}
