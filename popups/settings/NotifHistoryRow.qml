import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.utilities

Item {
    id: root

    property var notif: null
    property bool isFirst: true
    property bool isLast: true
    property bool flat: false

    signal dismissed()

    readonly property real outerRadius: 20
    readonly property real innerRadius: 5

    function setGroupShape(first, last) {
        isFirst = first;
        isLast = last;
    }

    readonly property string iconUrl: {
        if (!root.notif)
            return "";
        const icon = root.notif.appIcon;
        if (!icon)
            return "";
        if (icon.startsWith("/") || icon.startsWith("file://") || icon.startsWith("http"))
            return icon;
        return Quickshell.iconPath(icon, true) || "";
    }

    readonly property bool hasBody: root.notif !== null && root.notif.body.length > 0
readonly property string summary: {
        if (!root.notif)
            return "";
        return root.notif.summary.length > 0 ? root.notif.summary : "(no summary)";
    }

    readonly property real iconInset: Layout.s(18)
    readonly property real textInset: Layout.s(42)

    implicitHeight: Layout.s(22) + Layout.s(18) + (hasBody ? Layout.s(4) + bodyText.implicitHeight : 0)

    Rectangle {
        anchors.fill: parent
        z: -1
        color: rowMouse.containsMouse
            ? Qt.tint(Theme.surface_container_high, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08))
            : (root.flat ? "transparent" : Theme.surface_container)
        topLeftRadius: root.flat ? 14 : (root.isFirst ? root.outerRadius : root.innerRadius)
        topRightRadius: root.flat ? 14 : (root.isFirst ? root.outerRadius : root.innerRadius)
        bottomLeftRadius: root.flat ? 14 : (root.isLast ? root.outerRadius : root.innerRadius)
        bottomRightRadius: root.flat ? 14 : (root.isLast ? root.outerRadius : root.innerRadius)

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    Text {
        id: timeText
        anchors.right: parent.right
        anchors.rightMargin: Layout.s(16)
        anchors.top: parent.top
        anchors.topMargin: Layout.s(11)
        text: root.notif ? root.notif.timeStr : ""
        color: rowMouse.containsMouse ? Theme.on_surface_variant : Theme.outline
        font {
            family: Layout.fontSans
            pixelSize: Layout.ts(11)
        }

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    Item {
        id: headerRow
        anchors.left: parent.left
        anchors.leftMargin: Layout.s(14)
        anchors.right: timeText.left
        anchors.rightMargin: Layout.s(12)
        anchors.top: parent.top
        anchors.topMargin: Layout.s(9)
        height: Layout.s(18)

        IconImage {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: root.iconInset
            height: root.iconInset
            source: root.iconUrl
            visible: root.iconUrl.length > 0
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: root.textInset
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.summary
            color: Theme.on_surface
            elide: Text.ElideRight
            font {
                family: Layout.fontSans
                pixelSize: Layout.ts(13)
                weight: Font.Medium
            }
        }
    }

    Text {
        id: bodyText
        anchors.left: parent.left
        anchors.leftMargin: Layout.s(14) + root.textInset
        anchors.right: parent.right
        anchors.rightMargin: Layout.s(16)
        anchors.top: headerRow.bottom
        anchors.topMargin: Layout.s(4)
        text: root.hasBody ? Markup.sanitize(root.notif.body) : ""
        textFormat: Text.RichText
        linkColor: Theme.primary
        color: Theme.on_surface_variant
        wrapMode: Text.WordWrap
        maximumLineCount: 3
        elide: Text.ElideRight
        visible: root.hasBody
        font {
            family: Layout.fontSans
            pixelSize: Layout.ts(12)
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.notif)
                root.notif.close();
            root.dismissed();
        }
    }
}