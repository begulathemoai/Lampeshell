import QtQuick
import qs.theme

Item {
    id: root

    property string title: ""
    property var model: []
    property string current: ""
    property string checkIcon: "check"

    property bool open: false

    signal chosen(string value)
    signal dismissed()

    visible: open
    opacity: open ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: Motion.emphasized
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            onClicked: root.dismissed()
        }
    }

    Rectangle {
        id: sheet
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 420)
        height: sheetColumn.implicitHeight + 32
        radius: 28
        color: Theme.surface_container_high
        border.width: 1
        border.color: Theme.outline_variant

        scale: root.open ? 1 : 0.94
        Behavior on scale {
            NumberAnimation {
                duration: Motion.emphasized
                easing.type: Easing.OutCubic
            }
        }

        Column {
            id: sheetColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 10

            Text {
                width: parent.width
                text: root.title
                color: Theme.on_surface
                font {
                    family: "Google Sans"
                    pixelSize: 18
                    weight: Font.Medium
                }
            }

            Repeater {
                model: root.model

                delegate: Rectangle {
                    required property var modelData

                    readonly property bool isCurrent: root.current === modelData.key

                    width: sheetColumn.width
                    height: 50
                    radius: 18
                    color: isCurrent
                        ? Theme.primary_container
                        : (optionMouse.containsMouse
                            ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)
                            : "transparent")

                    Behavior on color {
                        ColorAnimation {
                            duration: 110
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        color: isCurrent ? Theme.on_primary_container : Theme.on_surface
                        font {
                            family: "Google Sans"
                            pixelSize: 14
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        visible: isCurrent
                        text: root.checkIcon
                        color: Theme.on_primary_container
                        font {
                            family: "Material Symbols Rounded"
                            pixelSize: 20
                        }
                    }

                    MouseArea {
                        id: optionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.chosen(modelData.key)
                    }
                }
            }

            Text {
                anchors.right: parent.right
                width: parent.width
                horizontalAlignment: Text.AlignRight
                text: "Cancel"
                color: Theme.primary
                font {
                    family: "Google Sans"
                    pixelSize: 14
                    weight: Font.Medium
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -10
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.dismissed()
                }
            }
        }
    }
}