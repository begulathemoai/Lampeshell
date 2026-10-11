import QtQuick
import QtQuick.Controls
import qs.theme
import qs.popups.nexus

/**
 * Shared chrome for every settings page: a title header that grows a back button
 * when the page is pushed as a sub-page, and a scrollable body.
 *
 * Page files declare their body as plain children; they are reparented into the
 * scrollable column by the default property alias.
 */
Item {
    id: root

    required property NexusState nState

    property string title: ""
    property string description: ""
    property bool isSubPage: false

    // Sub-pages get a back affordance unless they opt out (a root page can be
    // pushed onto the stack too, and should still be able to go back).
    readonly property bool showBack: nState.subPageIdxStack.length > 0

    default property alias body: content.data

    implicitHeight: header.implicitHeight + 18 + flick.contentHeight

    // --- Header ---
    Item {
        id: header
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

    // --- Scrollable body ---
    Flickable {
        id: flick
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.topMargin: 18
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
}
