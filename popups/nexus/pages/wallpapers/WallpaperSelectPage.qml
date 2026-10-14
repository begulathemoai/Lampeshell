import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import qs.theme
import qs.services
import qs.popups.settings
import qs.popups.nexus
import qs.popups.nexus.common
import qs.popups.nexus.pages.wallpapers

PageBase {
    id: root

    title: "Wallpaper"
    description: "Pick an image; the accent and every app theme follow it"
    isSubPage: true

    property string query: ""
    property string category: ""

    readonly property int columns: Math.max(2, Math.floor(width / 180))
    readonly property int cellWidth: Math.floor((width - (columns - 1) * 12) / columns)
    readonly property int cellHeight: Math.round(root.cellWidth / 1.6) + 30

    readonly property var pool: {
        const q = root.query.trim().toLowerCase();
        const src = ThemeService.entries;
        const out = [];

        for (const w of src) {
            if (q.length > 0 && w.name.toLowerCase().indexOf(q) < 0)
                continue;
            if (root.category.length > 0 && w.category !== root.category)
                continue;
            out.push(w);
        }

        return out;
    }

    readonly property var chips: ["", ...ThemeService.categoryNames]

    function chipLabel(chip) {
        return chip.length > 0 ? chip : "All";
    }

    Component.onCompleted: ThemeService.refresh()

    SettingsCard {
        title: "Current"
        subtitle: ThemeService.hasWallpaper
            ? ThemeService.currentWallpaper.split("/").pop()
            : "No wallpaper applied"

        Row {
            spacing: 10

            ActionButton {
                text: "Refresh list"
                icon: "refresh"
                enabled: !ThemeService.busy
                onTriggered: ThemeService.refresh()
            }

            ActionButton {
                text: "Revert"
                icon: "undo"
                enabled: ThemeService.hasWallpaper && !ThemeService.busy
                onTriggered: ThemeService.revertTheme()
            }
        }
    }

    Item {
        width: parent.width
        height: 44

        Rectangle {
            id: searchBg

            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: addButton.left
            anchors.rightMargin: 10
            radius: height / 2
            color: Theme.surface_container_highest
            border.width: searchInput.activeFocus ? 2 : 0
            border.color: Theme.primary

            Behavior on border.width {
                NumberAnimation {
                    duration: 120
                }
            }

            Text {
                id: searchIcon

                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "search"
                color: Theme.on_surface_variant
                font {
                    family: "Material Symbols Rounded"
                    pixelSize: 18
                }
            }

            TextField {
                id: searchInput

                anchors.left: searchIcon.right
                anchors.leftMargin: 10
                anchors.right: searchClear.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                background: null
                padding: 0
                text: root.query
                placeholderText: "Filter by name"
                placeholderTextColor: Theme.on_surface_variant
                color: Theme.on_surface
                selectByMouse: true
                font {
                    family: "Google Sans"
                    pixelSize: 13
                }
                cursorDelegate: Rectangle {
                    width: 2
                    color: Theme.primary
                }
                onTextChanged: root.query = text
            }

            Item {
                id: searchClear

                visible: searchInput.text.length > 0
                width: visible ? 32 : 0
                height: 32
                anchors.right: parent.right
                anchors.rightMargin: visible ? 6 : 0
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    radius: 14
                    color: clearMouse.containsMouse
                        ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.10)
                        : "transparent"
                }

                Text {
                    anchors.centerIn: parent
                    text: "close"
                    color: Theme.on_surface_variant
                    font {
                        family: "Material Symbols Rounded"
                        pixelSize: 16
                    }
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: searchInput.text = ""
                }
            }
        }

        ActionButton {
            id: addButton

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "Add"
            icon: "add_photo_alternate"
            enabled: !ThemeService.busy
            onTriggered: fileDialog.open()
        }
    }

    Flow {
        id: chipRow

        width: parent.width
        visible: ThemeService.categoryNames.length > 0
        spacing: 8

        Repeater {
            model: root.chips

            delegate: Rectangle {
                id: chipItem

                required property var modelData

                readonly property bool active: modelData === root.category

                height: 30
                width: label.implicitWidth + 26
                radius: 15
                color: active ? Theme.primary : Theme.surface_container_highest
                border.width: 1
                border.color: active ? Theme.primary : Theme.outline_variant

                Behavior on color {
                    ColorAnimation {
                        duration: 130
                    }
                }

                Text {
                    id: label

                    anchors.centerIn: parent
                    text: root.chipLabel(modelData)
                    color: chipItem.active ? Theme.on_primary : Theme.on_surface_variant
                    font {
                        family: "Google Sans"
                        pixelSize: 11
                        weight: chipItem.active ? Font.Medium : Font.Normal
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.category = modelData
                }
            }
        }
    }

    Text {
        width: parent.width
        visible: ThemeService.categoryNames.length > 0 && root.query.trim().length === 0
        text: ThemeService.entries.length + " wallpaper(s) in "
            + (root.category.length > 0 ? root.category : "all folders")
        color: Theme.on_surface_variant
        font {
            family: "Google Sans"
            pixelSize: 11
        }
    }

    GridView {
        id: grid

        width: parent.width
        height: Math.max(0, Math.min(contentHeight, root.height - 250))
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        model: root.pool
        cellWidth: root.cellWidth + 12
        cellHeight: root.cellHeight

        ScrollBar.vertical: ScrollBar {}

        delegate: WallpaperTile {

            required property var modelData
            width: root.cellWidth
            entry: modelData
            currentPath: ThemeService.currentWallpaper
            enabled: !ThemeService.busy
            onClicked: ThemeService.applyWallpaper(modelData.path)
        }
    }

    Text {
        width: parent.width
        visible: grid.count === 0
        horizontalAlignment: Text.AlignHCenter
        text: ThemeService.entries.length === 0
            ? "No wallpapers yet. Use Add to copy an image into " + ThemeService.wallDir
            : "Nothing matches that filter."
        color: Theme.on_surface_variant
        wrapMode: Text.WordWrap
        font {
            family: "Google Sans"
            pixelSize: 12
        }
    }

    FileDialog {
        id: fileDialog

        title: "Add a wallpaper"
        nameFilters: [
            "Images (*.png *.jpg *.jpeg *.webp *.bmp *.jxl)",
            "All files (*)"
        ]
        onAccepted: ThemeService.importImage(selectedFile.toString().replace("file://", ""))
    }
}