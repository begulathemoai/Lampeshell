import QtQuick
import QtQuick.Effects
import qs.theme

Rectangle {
    id: root

    property color surfaceColor: Theme.surface_container_lowest
    property bool elevated: true

    color: root.surfaceColor

    // Corners flush with the bar edge stay square so the panel merges into the
    // bar; the free-floating outer corners keep the larger panel radius.
    topLeftRadius: Layout.barAtTop || Layout.barAtLeft ? 0 : Layout.panelRadius
    topRightRadius: Layout.barAtTop || Layout.barAtRight ? 0 : Layout.panelRadius
    bottomLeftRadius: Layout.barAtBottom || Layout.barAtLeft ? 0 : Layout.panelRadius
    bottomRightRadius: Layout.barAtBottom || Layout.barAtRight ? 0 : Layout.panelRadius

    layer.enabled: root.elevated
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(Theme.shadow.r, Theme.shadow.g, Theme.shadow.b, 0.69)
        blurMax: 20
        shadowBlur: 0.5
    }

    default property alias contentData: content.data

    Item {
        id: content

        anchors.fill: parent
    }
}
