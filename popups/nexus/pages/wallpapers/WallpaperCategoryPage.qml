import QtQuick
import QtQuick.Controls
import qs.theme
import qs.services
import qs.popups.nexus
import qs.popups.nexus.common
import qs.popups.nexus.pages.wallpapers

PageBase {
    id: root

    readonly property string category: root.nState.selectedWallpaperCategory ?? ""
    readonly property var walls: ThemeService.wallsInCategory(category)

    title: category.length > 0 ? category : "Category"
    description: walls.length + " wallpaper(s)"
    isSubPage: true

    readonly property int columns: Math.max(2, Math.floor(width / 190))
    readonly property int cellWidth: Math.floor((width - (columns - 1) * 12) / columns)

    GridView {
        id: grid

        width: parent.width
        height: Math.max(0, Math.min(contentHeight, 520))
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        model: root.walls
        cellWidth: root.cellWidth + 12
        cellHeight: Math.round(root.cellWidth / 1.6) + 30

        ScrollBar.vertical: ScrollBar {}

        delegate: WallpaperTile {

            required property var modelData
            width: root.cellWidth
            entry: modelData
            currentPath: ThemeService.currentWallpaper
            onClicked: ThemeService.applyWallpaper(modelData.path)
        }
    }

    Text {
        width: parent.width
        visible: root.walls.length === 0
        horizontalAlignment: Text.AlignHCenter
        text: "This category is empty."
        color: Theme.on_surface_variant
        font {
            family: "Google Sans"
            pixelSize: 12
        }
    }
}
