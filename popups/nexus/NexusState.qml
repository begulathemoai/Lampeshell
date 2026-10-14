import QtQuick

QtObject {
    id: root

    required property var host

    property var quickSettingsBackend
    property var targetScreen

    property bool overlayOpen: false

    property int currentPageIdx: 0
    readonly property var subPageIdxStack: []

    property var selectedBtDevice: null
    property var selectedNetwork: null

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

    onCurrentPageIdxChanged: subPageIdxStack.length = 0
}
