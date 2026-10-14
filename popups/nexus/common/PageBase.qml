import QtQuick
import QtQuick.Controls
import qs.theme
import qs.popups.nexus

Item {
    id: root

    required property NexusState nState

    property string title: ""
    property string description: ""
    property bool isSubPage: false
    property bool showHeader: true

    readonly property bool showBack: nState.subPageIdxStack.length > 0

    function findLabelY(item, label, baseY) {
        for (let i = 0; i < item.children.length; i++) {
            const child = item.children[i];
            const y = baseY + child.y;
            if (child.visible !== false && (child.label === label || child.title === label))
                return y;
            const sub = root.findLabelY(child, label, y);
            if (sub >= 0)
                return sub;
        }
        return -1;
    }

    function revealByLabel(label) {
        const y = root.findLabelY(content, label, 0);
        if (y < 0)
            return;
        scrollAnim.to = Math.max(0, Math.min(y - 24, flick.contentHeight - flick.height));
        scrollAnim.start();
    }

    default property alias body: content.data
    property alias overlay: overlayLayer.data

    implicitHeight: (root.showHeader ? header.implicitHeight + 18 : 0) + flick.contentHeight

    Item {
        id: header
        visible: root.showHeader
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        implicitHeight: Math.max(backButton.visible ? backButton.height : 0, titleCol.implicitHeight)

        Rectangle {
            id: backButton
            visible: root.showBack
            width: 34
            height: 34
            radius: 17
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: backMouse.containsMouse
                ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.10)
                : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: 110
                }
            }

            Text {
                anchors.centerIn: parent
                text: "arrow_back"
                color: Theme.on_surface_variant
                font {
                    family: "Material Symbols Rounded"
                    pixelSize: 19
                }
            }

            MouseArea {
                id: backMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.nState.closeSubPage()
            }
        }

        Column {
            id: titleCol
            anchors.left: backButton.visible ? backButton.right : parent.left
            anchors.leftMargin: backButton.visible ? 14 : 0
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                text: root.title
                elide: Text.ElideRight
                color: Theme.on_surface
                font {
                    family: "Google Sans"
                    pixelSize: 19
                    weight: Font.Medium
                }
            }

            Text {
                width: parent.width
                visible: root.description.length > 0
                text: root.description
                elide: Text.ElideRight
                color: Theme.on_surface_variant
                font {
                    family: "Google Sans"
                    pixelSize: 12
                }
            }
        }
    }

    Flickable {
        id: flick
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: root.showHeader ? header.bottom : parent.top
        anchors.topMargin: root.showHeader ? 18 : 0
        anchors.bottom: parent.bottom
        clip: true
        contentWidth: width
        contentHeight: content.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {}

        Column {
            id: content
            width: flick.contentWidth
            spacing: 18
        }
    }

    Item {
        id: overlayLayer
        anchors.fill: parent
        z: 100
    }

    NumberAnimation {
        id: scrollAnim
        target: flick
        property: "contentY"
        duration: 260
        easing.type: Easing.OutCubic
    }
}
