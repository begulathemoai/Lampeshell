pragma Singleton

import QtQuick
import qs.theme

Item {
    id: root

    implicitWidth: 0
    implicitHeight: 0


    property real panelWidth: 0
    readonly property real leftInset: Layout.s(18)
    readonly property real rightInset: 0

    property real panelHeight: 0

    property bool open: false

    readonly property bool merged: panelHeight > 0.5

    readonly property real fillet: Math.min(Layout.cornerRadius, panelHeight / 2)

    function setContentSize(w, h) {
        if (panelWidth !== w)
            panelWidth = w;
        targetHeight = h;
    }

    property real targetHeight: 0

    onOpenChanged: {
        panelHeightAnim.from = panelHeight;
        panelHeightAnim.to = open ? targetHeight : 0;
        panelHeightAnim.restart();
    }

    NumberAnimation {
        id: panelHeightAnim
        target: root
        property: "panelHeight"
        duration: 400
        easing.type: Easing.OutCubic
    }
}