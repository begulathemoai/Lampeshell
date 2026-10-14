import QtQuick
import QtQuick.Controls
import qs.theme
import qs.popups.nexus
import qs.popups.nexus.common

Item {
    id: root

    required property var nState

    signal resultActivated(var entry)

    implicitWidth: 360

    readonly property string query: search.text.toLowerCase().trim()

    readonly property var groups: {
        const out = [];
        for (const page of PageRegistry.pages) {
            let group = out.length > 0 && out[out.length - 1].category === page.category
                ? out[out.length - 1]
                : null;
            if (group === null) {
                group = { category: page.category, pages: [] };
                out.push(group);
            }
            group.pages.push(page);
        }
        return out;
    }

    readonly property var results: {
        const q = root.query;
        if (q.length === 0)
            return [];
        const out = [];
        for (const page of PageRegistry.pages) {
            const pageHay = ((page.label ?? "") + " " + (page.description ?? "") + " " + (page.category ?? "")).toLowerCase();
            if (pageHay.includes(q)) {
                out.push({
                    page: page.label,
                    title: page.label,
                    desc: page.description,
                    icon: page.icon,
                    isPage: true
                });
            }
            for (const entry of SettingsIndex.entries) {
                if (entry.page !== page.label)
                    continue;
                const hay = ((entry.title ?? "") + " " + (entry.desc ?? "") + " " + (entry.keywords ?? "")).toLowerCase();
                if (hay.includes(q)) {
                    out.push({
                        page: page.label,
                        title: entry.title,
                        desc: entry.desc,
                        icon: entry.icon ?? page.icon,
                        subPage: entry.subPage,
                        isPage: false
                    });
                }
            }
        }
        return out;
    }

    SearchField {
        id: search
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.topMargin: 16
    }

    Flickable {
        id: flick
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: search.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.topMargin: 16
        anchors.bottomMargin: 16
        clip: true
        contentWidth: width
        contentHeight: content.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ThemedScrollBar {}

        Item {
            id: content
            width: flick.contentWidth
            implicitHeight: root.query.length === 0
                ? navGroups.implicitHeight
                : (root.results.length > 0 ? searchResults.implicitHeight : noResults.implicitHeight)

            Column {
                id: navGroups
                width: content.width
                visible: root.query.length === 0
                spacing: 4

                Repeater {
                    model: root.groups

                    delegate: Column {
                        id: group
                        required property var modelData

                        width: navGroups.width
                        spacing: 4

                        Text {
                            text: {
                                const c = group.modelData.category ?? "";
                                return c.length === 0 ? "" : c.charAt(0).toUpperCase() + c.slice(1);
                            }
                            width: parent.width
                            color: Theme.primary
                            topPadding: 16
                            bottomPadding: 8
                            font {
                                family: Layout.fontSans
                                pixelSize: 14
                                weight: Font.Medium
                            }
                        }

                        Repeater {
                            model: group.modelData.pages

                            delegate: NavRow {
                                id: entry
                                required property var modelData
                                required property int index

                                width: group.width

                                isFirst: index === 0
                                isLast: index === group.modelData.pages.length - 1

                                page: entry.modelData
                                selected: root.nState.currentPageIdx === root.pageIndexFor(entry.modelData)

                                onClicked: root.nState.currentPageIdx = root.pageIndexFor(entry.modelData)
                            }
                        }
                    }
                }
            }

            Column {
                id: searchResults
                width: content.width
                visible: root.query.length > 0 && root.results.length > 0
                spacing: 4

                Repeater {
                    model: root.results

                    delegate: SearchResultRow {
                        required property var modelData
                        required property int index

                        width: searchResults.width

                        isFirst: index === 0
                        isLast: index === root.results.length - 1

                        entry: modelData

                        onClicked: root.resultActivated(modelData)
                    }
                }
            }

            Column {
                id: noResults
                width: content.width
                visible: root.query.length > 0 && root.results.length === 0
                topPadding: 32
                spacing: 8

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "search"
                    color: Theme.on_surface_variant
                    font {
                        family: Layout.fontIcons
                        pixelSize: 36
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No results"
                    color: Theme.on_surface
                    font {
                        family: Layout.fontSans
                        pixelSize: 16
                        weight: Font.Medium
                    }
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "Nothing matches \"" + search.text + "\""
                    elide: Text.ElideRight
                    color: Theme.on_surface_variant
                    font {
                        family: Layout.fontSans
                        pixelSize: 14
                    }
                }
            }
        }
    }

    function pageIndexFor(page) {
        for (let i = 0; i < PageRegistry.pages.length; i++) {
            if (PageRegistry.pages[i].label === page.label)
                return i;
        }
        return -1;
    }
}
