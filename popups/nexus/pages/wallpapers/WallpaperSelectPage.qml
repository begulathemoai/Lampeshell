import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.popups.settings
import qs.popups.nexus
import qs.popups.nexus.common
import qs.popups.nexus.pages.wallpapers

PageBase {
    id: root

    title: "Wallpaper"
    description: "Pick an image; the accent is generated from it"
    isSubPage: true

    readonly property int columns: Math.max(2, Math.floor(width / 190))
    readonly property int cellWidth: Math.floor((width - (columns - 1) * 12) / columns)

    Component.onCompleted: ThemeService.refresh()

    SettingsCard {
        title: "Current"
        subtitle: ThemeService.hasWallpaper
            ? ThemeService.currentWallpaper.split("/").pop()
            : "No wallpaper applied."

        Row {
            spacing: 10

            ActionButton {
                text: ThemeService.busy ? "Working..." : "Regenerate colours"
                icon: "palette"
                enabled: ThemeService.hasWallpaper && !ThemeService.busy
                onTriggered: ThemeService.applyWallpaper(ThemeService.currentWallpaper)
            }

            ActionButton {
                text: "Refresh list"
                icon: "refresh"
                onTriggered: ThemeService.refresh()
            }
        }
    }

    Text {
        width: parent.width
        visible: ThemeService.lastError.length > 0
        text: ThemeService.lastError
        color: Theme.critical
        wrapMode: Text.WordWrap
        font {
            family: "Google Sans"
            pixelSize: 11
        }
    }

    GridView {
        id: grid

        width: parent.width
        height: Math.max(0, Math.min(contentHeight, 460))
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        model: ThemeService.topLevelWalls
        cellWidth: root.cellWidth + 12
        cellHeight: Math.round(root.cellWidth / 1.6) + 30

        ScrollBar.vertical: ScrollBar {}

        delegate: WallpaperTile {

            required property var modelData
            width: root.cellWidth
            entry: modelData
            currentPath: ThemeService.currentWallpaper
            onClicked: {

                if (modelData.category.length > 0) {
                    root.nState.selectedWallpaperCategory = modelData.category;
                    root.nState.openSubPage(2);
                } else {
                    ThemeService.applyWallpaper(modelData.path);
                }
            }
        }
    }

    Text {
        width: parent.width
        visible: grid.count === 0
        horizontalAlignment: Text.AlignHCenter
        text: "No wallpapers found in ~/Pictures/walls"
        color: Theme.on_surface_variant
        font {
            family: "Google Sans"
            pixelSize: 12
        }
    }
}
