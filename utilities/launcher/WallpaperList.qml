import QtQuick
import Quickshell
import QtQuick.Effects
import "../../theme"
import qs.services

PathView {
    id: root

    property string searchQuery: ""

    signal itemChosen(var entry)

    function queryClean() {
        var s = searchQuery.trim();
        if (s.startsWith(">wallpaper "))
            return s.slice(11).trim().toLowerCase();
        if (s.startsWith(">wallpaper"))
            return s.slice(10).trim().toLowerCase();
        if (s.startsWith(">wall "))
            return s.slice(6).trim().toLowerCase();
        if (s.startsWith(">wall"))
            return s.slice(5).trim().toLowerCase();
        return s.toLowerCase();
    }

    readonly property var wallpapersList: {
        const q = queryClean();
        const all = ThemeService.entries;
        if (!q || q.length === 0)
            return all;
        return all.filter(w => {
            const name = (w.name || "").toLowerCase();
            const cat = (w.category || "").toLowerCase();
            const path = (w.path || "").toLowerCase();
            return name.includes(q) || cat.includes(q) || path.includes(q);
        });
    }

    readonly property var currentItem: count > 0 ? wallpapersList[currentIndex] : null

    readonly property int itemWidth: 330

    readonly property int numItems: {
        const maxWidth = 1200;
        const maxItemsOnScreen = Math.floor(maxWidth / itemWidth);
        const visible = Math.min(maxItemsOnScreen, wallpapersList.length);
        if (visible === 2)
            return 1;
        if (visible > 1 && visible % 2 === 0)
            return visible - 1;
        return visible;
    }

    function next() {
        if (count > 0)
            currentIndex = (currentIndex + 1) % count;
    }

    function prev() {
        if (count > 0)
            currentIndex = (currentIndex - 1 + count) % count;
    }

    function confirmSelection() {
        if (currentItem)
            itemChosen(currentItem);
    }

    Component.onCompleted: {
        ThemeService.refresh();
        if (count > 0) {
            const idx = wallpapersList.findIndex(w => w.path === ThemeService.currentWallpaper);
            currentIndex = idx >= 0 ? idx : 0;
            triggerPreview();
        }
    }

    onWallpapersListChanged: {
        if (count > 0) {
            const idx = wallpapersList.findIndex(w => w.path === ThemeService.currentWallpaper);
            currentIndex = idx >= 0 ? idx : 0;
            triggerPreview();
        }
    }

    Component.onDestruction: {
        ThemeService.stopPreview();
    }

    onCurrentItemChanged: {
        if (currentItem && currentItem.path)
            ThemeService.preview(currentItem.path);
    }

    function triggerPreview() {
        if (currentItem && currentItem.path)
            ThemeService.preview(currentItem.path);
    }

    implicitWidth: Math.min(numItems, count) * itemWidth
    pathItemCount: numItems
    cacheItemCount: 4

    model: wallpapersList

    snapMode: PathView.SnapToItem
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    highlightRangeMode: PathView.StrictlyEnforceRange

    delegate: WallpaperItem {
        required property var modelData
        modelData: modelData
    }

    path: Path {
        startY: root.height / 2

        PathAttribute { name: "z"; value: 0 }
        PathLine {
            x: root.width / 2
            relativeY: 0
        }
        PathAttribute { name: "z"; value: 1 }
        PathLine {
            x: root.width
            relativeY: 0
        }
    }

    MouseArea {
        anchors.fill: parent
        onWheel: function(wheel) {
            if (wheel.angleDelta.y > 0)
                root.decrementCurrentIndex();
            else if (wheel.angleDelta.y < 0)
                root.incrementCurrentIndex();
        }
    }
}
