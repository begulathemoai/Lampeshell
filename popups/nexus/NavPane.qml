import QtQuick
import QtQuick.Controls
import qs.theme
import qs.popups.nexus

/**
 * Settings navigation pane, matching Metrolist's SettingsNavigationPane.
 *
 * Entries are grouped, and within a group they use connected corners so the
 * run reads as a single card rather than a stack of separate buttons. Group
 * headings are labelLarge in the primary colour, inset 16dp, with normal
 * capitalisation - only the first letter is capitalised.
 */
Item {
    id: root

    required property var nState

    implicitWidth: 272

    // Flat registry -> grouped model, so each group's first/last entry can be
    // marked for the connected shape.
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

    Flickable {
        id: flick
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        clip: true
        contentWidth: width
        contentHeight: list.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {}

        Column {
            id: list
            width: flick.contentWidth
            y: 16
            spacing: 4

            Repeater {
                model: root.groups

                delegate: Column {
                    id: group
                    required property var modelData

                    width: list.width
                    spacing: 4

                    Text {
                        // Only the first letter is capitalised; no forced caps.
                        text: {
                            const c = group.modelData.category ?? "";
                            return c.length === 0 ? "" : c.charAt(0).toUpperCase() + c.slice(1);
                        }
                        width: parent.width
                        color: Theme.primary
                        leftPadding: 16
                        topPadding: 16
                        bottomPadding: 8
                        font {
                            family: "Google Sans"
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

                            // Connected corners within this group only.
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
    }

    // Pages are identified by label, so find the index rather than threading an
    // index through the grouped model.
    function pageIndexFor(page) {
        for (let i = 0; i < PageRegistry.pages.length; i++) {
            if (PageRegistry.pages[i].label === page.label)
                return i;
        }
        return -1;
    }
}
