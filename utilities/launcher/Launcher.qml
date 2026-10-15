import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import "../../theme"
import qs.services

PanelWindow {
    id: launcherWindow

    property var hiddenKeywords: ["avahi", "uuctl", "bssh", "bvnc"]

    color: "transparent"
    visible: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "launcher_overlay"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: -1

    anchors.bottom: true
    margins.bottom: Layout.bottomBarHeight

    function screenForFocus() {
        const active = Hyprland.focusedMonitor ?? null;
        return active && active.name ? Quickshell.screens.find(s => s.name === active.name) ?? Quickshell.screens[0] : Quickshell.screens[0];
    }
    property var targetScreen: screenForFocus()
    screen: targetScreen

    implicitWidth: Math.round(contentRoot.width)

    readonly property real maxContentHeight: 16 + ((57 + 8) * 7 - 8) + 16 + searchField.height + 6
    implicitHeight: Math.round(maxContentHeight)

    function scoreMatch(text, query) {
        if (!text)
            return -1;
        var textLower = text.toString().toLowerCase();
        var queryLower = query.toLowerCase();

        if (textLower === queryLower)
            return 1000;

        if (textLower.startsWith(queryLower))
            return 800;

        var words = textLower.split(/[\s\-_]+/);
        for (var i = 0; i < words.length; i++) {
            if (words[i].startsWith(queryLower))
                return 600;
        }

        if (query.length >= 3 && textLower.indexOf(queryLower) !== -1)
            return 200;

        return -1;
    }

    function toListEntry(entry) {
        return {
            name: entry.name || "",
            comment: entry.comment || "",
            genericName: entry.genericName || "",
            icon: entry.icon || "",
            id: entry.id || "",
            keywords: entry.keywords || [],
            execString: entry.execString || "",
            command: entry.command || [],
            runInTerminal: !!entry.runInTerminal,
            workingDirectory: entry.workingDirectory || ""
        };
    }

    function isHiddenApp(name) {
        if (!name)
            return false;
        var nameLower = name.toLowerCase();
        return hiddenKeywords.some(keyword => nameLower.includes(keyword));
    }

    function buildFilteredList() {
        var query = ctrl.searchText.trim();

        if (query.startsWith(">calc ")) {
            if (ctrl.calcPending)
                return [{ name: "Calculating…", genericName: query.slice(6).trim(), icon: "calculate", __calc: false }];
            if (ctrl.calcError !== "")
                return [{ name: ctrl.calcError, genericName: "Not a valid expression", icon: "calculate", __calc: false }];
            if (ctrl.calcResult !== "")
                return [{ name: "= " + ctrl.calcResult, genericName: "Enter to copy", icon: "calculate", __calc: true }];
            return [];
        }

        if (query.startsWith(">")) {
            var actionQuery = query.replace(/^>\s*/, "").toLowerCase();
            var actions = ctrl.actions;
            if (actionQuery === "") {
                return actions.map(function(a) {
                    return { name: a.name, genericName: a.description, icon: a.icon, __action: a };
                });
            }
            var scored = [];
            for (var ai = 0; ai < actions.length; ai++) {
                var act = actions[ai];
                var s = Math.max(launcherWindow.scoreMatch(act.name, actionQuery),
                                 launcherWindow.scoreMatch(act.description, actionQuery));
                if (s >= 0)
                    scored.push({ entry: act, score: s });
            }
            scored.sort(function(a, b) { return b.score - a.score; });
            return scored.map(function(x) {
                return { name: x.entry.name, genericName: x.entry.description, icon: x.entry.icon, __action: x.entry };
            });
        }

        var allApps = DesktopEntries.applications.values;
        var queryLower = query.toLowerCase();

        if (query === "") {
            return allApps
                .filter(app => !launcherWindow.isHiddenApp(app.name))
                .sort((a, b) => (a.name || "").localeCompare(b.name || ""))
                .map(app => launcherWindow.toListEntry(app));
        }

        var isSearchingHidden = hiddenKeywords.some(keyword => queryLower.includes(keyword));
        var scored = [];

        for (var i = 0; i < allApps.length; i++) {
            var entry = allApps[i];

            if (launcherWindow.isHiddenApp(entry.name) && !isSearchingHidden) {
                continue;
            }

            var best = scoreMatch(entry.name, query);

            if (entry.genericName) {
                var s = scoreMatch(entry.genericName, query);
                if (s >= 200)
                    best = Math.max(best, s - 50);
            }

            if (entry.comment) {
                var s = scoreMatch(entry.comment, query);
                if (s >= 200)
                    best = Math.max(best, s - 100);
            }

            if (entry.keywords) {
                for (var j = 0; j < entry.keywords.length; j++) {
                    var s = scoreMatch(entry.keywords[j], query);
                    if (s >= 200)
                        best = Math.max(best, s - 20);
                }
            }

            if (entry.execString && entry.execString.toLowerCase().includes(queryLower)) {
                best = Math.max(best, 180);
            }

            if (best >= 0) {
                scored.push({
                    entry: entry,
                    score: best
                });
            }
        }

        scored.sort((a, b) => {
            if (b.score !== a.score)
                return b.score - a.score;
            return (a.entry.name || "").localeCompare(b.entry.name || "");
        });

        return scored.map(s => launcherWindow.toListEntry(s.entry));
    }

    LauncherBackend {
        id: ctrl

        onOpenMenuRequested: {
            if (launcherWindow.shown)
                launcherWindow.closeMenu();
            else
                launcherWindow.openMenu();
        }

        onCloseMenuRequested: launcherWindow.closeMenu()
    }

    property bool shown: false

    function publishGeometry() {
        LauncherState.screenName = launcherWindow.screen ? launcherWindow.screen.name : "";
        LauncherState.setContentSize(Math.round(contentRoot.contentWidth), Math.round(contentRoot.contentHeight));
    }

    onWidthChanged: publishGeometry()
    onHeightChanged: publishGeometry()
    onTargetScreenChanged: publishGeometry()

    onShownChanged: LauncherState.open = shown

    function openMenu() {
        launcherWindow.targetScreen = launcherWindow.screenForFocus();
        launcherWindow.shown = true;
        publishGeometry();
        launcherWindow.visible = true;
        Qt.callLater(function() {
            focusGrab.active = true;
            contentRoot.focusSearch();
        });
    }

    function closeMenu() {
        if (!launcherWindow.shown && !launcherWindow.visible)
            return;
        launcherWindow.shown = false;
        focusGrab.active = false;
        hideWhenDone.restart();
    }

    function toggle() {
        if (launcherWindow.shown)
            closeMenu();
        else
            openMenu();
    }

    Timer {
        id: hideWhenDone
        interval: Motion.duration(Motion.defaultSpatial) + 50
        onTriggered: {
            if (!launcherWindow.shown)
                launcherWindow.visible = false;
        }
    }

    Connections {
        target: LauncherState

        function onToggleRequested() {
            launcherWindow.toggle();
        }

        function onOpenRequested() {
            launcherWindow.openMenu();
        }

        function onCloseRequested() {
            launcherWindow.closeMenu();
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [launcherWindow]
        active: false
        onCleared: launcherWindow.closeMenu()
    }

    Item {
        id: reveal

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: LauncherState.revealHeight
        clip: true

        Item {
            id: contentRoot

            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter

            width: card.width
            height: card.height

            readonly property real contentWidth: card.width
            readonly property real contentHeight: card.height

            onWidthChanged: launcherWindow.publishGeometry()
            onHeightChanged: launcherWindow.publishGeometry()

            function focusSearch() {
                searchField.forceActiveFocus();
            }

            Rectangle {
                id: card

                width: Math.min(632, (launcherWindow.screen ? launcherWindow.screen.width : 632) - 96)
                height: 16 + listArea.height + 16 + searchField.height + 6
                radius: Layout.panelRadius
                color: "transparent"

                Keys.onPressed: event => {
                    if (searchField.activeFocus)
                        return;

                    if (event.key === Qt.Key_Escape) {
                        launcherWindow.closeMenu();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Slash || event.key === Qt.Key_I) {
                        searchField.forceActiveFocus();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
                        listView.incrementCurrentIndex();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                        listView.decrementCurrentIndex();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                        if (listView.currentItem) {
                            listView.currentItem.launch();
                            ctrl.searchText = "";
                        }
                        event.accepted = true;
                    }
                }

                Item {
                    id: listArea

                    readonly property real targetHeight: listView.count > 0 ? listView.implicitHeight : emptyState.implicitHeight

                    width: parent.width - 32
                    height: targetHeight
                    anchors.top: parent.top
                    anchors.topMargin: 16
                    anchors.horizontalCenter: parent.horizontalCenter

                    Behavior on height {
                        enabled: launcherWindow.shown

                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    ListView {
                        id: listView

                        width: parent.width
                        height: parent.height
                        visible: count > 0
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        spacing: 8
                        currentIndex: 0
                        highlightFollowsCurrentItem: false
                        highlightRangeMode: ListView.ApplyRange
                        preferredHighlightBegin: 0
                        preferredHighlightEnd: height

                        implicitHeight: (57 + 8) * Math.min(7, count) - 8

                        model: ScriptModel {
                            values: launcherWindow.buildFilteredList()
                            onValuesChanged: listView.currentIndex = 0
                        }

                        delegate: LauncherDelegate {}

                        highlight: Rectangle {
                            radius: 16
                            color: Theme.on_surface
                            opacity: 0.08
                            y: listView.currentItem ? listView.currentItem.y : 0
                            width: listView.width
                            height: listView.currentItem ? listView.currentItem.height : 0

                            Behavior on y {
                                NumberAnimation {
                                    duration: Motion.duration(Motion.standard)
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        displaced: Transition {
                            NumberAnimation {
                                properties: "x,y"
                                duration: Motion.duration(Motion.defaultSpatial)
                                easing.type: Easing.OutCubic
                            }
                        }

                        add: Transition {
                            NumberAnimation {
                                property: "opacity"
                                to: 1
                                duration: Motion.duration(Motion.defaultEffects)
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Row {
                        id: emptyState

                        anchors.centerIn: parent
                        spacing: 12
                        opacity: listView.count === 0 ? 1 : 0
                        scale: listView.count === 0 ? 1 : 0.5

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Motion.duration(Motion.defaultEffects)
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: Motion.duration(Motion.defaultEffects)
                                easing.type: Easing.OutCubic
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "manage_search"
                            color: Theme.on_surface_variant

                            font {
                                family: "Material Symbols Rounded"
                                pointSize: 36
                                weight: Font.Normal
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: "No results"
                                color: Theme.on_surface_variant

                                font {
                                    family: "Google Sans"
                                    pointSize: 16
                                    weight: Font.Medium
                                }
                            }

                            Text {
                                text: "Try searching for something else"
                                color: Theme.on_surface_variant

                                font {
                                    family: "Google Sans"
                                    pointSize: 14
                                    weight: Font.Normal
                                }
                            }
                        }
                    }
                }

                TextField {
                    id: searchField

                    width: parent.width - 32
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    anchors.horizontalCenter: parent.horizontalCenter

                    topPadding: 14
                    bottomPadding: 14
                    leftPadding: searchIcon.width + 16 + 12
                    rightPadding: clearIcon.width + 12 + 12

                    font {
                        family: "Google Sans"
                        pointSize: 12
                        weight: Font.Normal
                    }

                    color: Theme.on_surface
                    selectionColor: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4)
                    selectedTextColor: color
                    verticalAlignment: TextInput.AlignVCenter

                    placeholderText: "Search apps..."
                    placeholderTextColor: Theme.on_surface_variant

                    background: Rectangle {
                        radius: height / 2
                        color: Theme.surface_container
                    }
                    text: ctrl.searchText
                    onTextChanged: {
                        ctrl.searchText = text;
                        listView.currentIndex = 0;
                    }

                    Keys.onEscapePressed: launcherWindow.closeMenu()

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                            if (listView.currentItem) {
                                listView.currentItem.launch();
                                ctrl.searchText = "";
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            listView.incrementCurrentIndex();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            listView.decrementCurrentIndex();
                            event.accepted = true;
                        }
                    }

                    Text {
                        id: searchIcon

                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter

                        text: "search"
                        color: Theme.on_surface_variant

                        font {
                            family: "Material Symbols Rounded"
                            pointSize: 16
                            weight: Font.Normal
                        }
                    }

                    Text {
                        id: clearIcon

                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter

                        text: "clear"
                        color: Theme.on_surface_variant
                        opacity: searchField.text.length > 0 ? 1 : 0

                        font {
                            family: "Material Symbols Rounded"
                            pointSize: 18
                            weight: Font.Normal
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Motion.duration(Motion.defaultEffects)
                                easing.type: Easing.OutCubic
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -8
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchField.text = "";
                                searchField.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }
    }
}
