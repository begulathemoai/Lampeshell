import QtQuick

/**
 * State for the settings surface, mirroring Caelestia's NexusState.
 *
 * Pages and sub-pages both navigate through here: a page index for the nav pane,
 * and a stack of sub-page indices on top of it. Sub-page state lives in the stack
 * rather than in each page, so switching nav pages and backing out of a detail
 * view stay consistent with each other.
 */
QtObject {
    id: root

    required property var host // the Settings window

    // Shared services, reached through here because page files are separate
    // components and cannot see the window's ids.
    property var accentPalette
    property var quickSettingsBackend
    property var targetScreen

    property int currentPageIdx: 0
    readonly property var subPageIdxStack: []

    // Whatever the detail view is currently working on. Caelestia stores the
    // selected device/entry here so it survives navigating away and back.
    property var selectedBtDevice: null
    property var selectedNetwork: null
    property string selectedWallpaperCategory: ""

    signal subPageOpened(idx: int)
    signal subPageClosed

    function openSubPage(idx: int): void {
        subPageIdxStack.push(idx);
        subPageOpened(idx);
    }

    function closeSubPage(): void {
        if (subPageIdxStack.length === 0)
            return;
        subPageClosed();
        subPageIdxStack.pop();
    }

    function close(): void {
        host.close();
    }

    // Changing section starts a fresh navigation stack, otherwise a detail view
    // from the previous section would still be showing.
    onCurrentPageIdxChanged: subPageIdxStack.length = 0
}
