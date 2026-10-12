pragma Singleton

import QtQuick

QtObject {
    property int topBarHeight: 65         // 50 base * 1.3 uiScale
    property int sideBarWidth: 78         // 10 base * 1.3 uiScale - 1.3 makes the sidebar a usable dock on 4K
    property int bottomBarHeight: 13     // 10 base * 1.3 uiScale

    property int cornerRadius: 20

    property real uiScale: 1.3

    property string targetMonitor: ""
}
