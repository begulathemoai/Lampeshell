import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import "../../theme"

PanelWindow {
    id: launcherWindow

    property var hiddenKeywords: ["avahi", "uuctl", "bssh", "bvnc"]

    color: "transparent"
    visible: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "launcher_overlay"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: -1

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

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

            return allApps.filter(app => !launcherWindow.isHiddenApp(app.name)).sort((a, b) => (a.name || "").localeCompare(b.name || ""));
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

        return scored.map(s => s.entry);
    }

    LauncherBackend {
        id: ctrl

        onOpenMenuRequested: {
            if (launcherWindow.visible && !launcherWindow.closing) {
                closeMenu();
            } else {
                openMenu();
            }
        }

        onCloseMenuRequested: closeMenu()
    }

    property bool closing: false
    property bool pointerHeld: false
    property bool closePending: false

    function openMenu() {
        ctrl.searchText = "";
        closing = false;
        closePending = false;
        closeWatchdog.stop();
        launcherScrim.opacity = 0;
        scrimAnim.restart();
        launcherWindow.visible = true;
    }

    function closeMenu() {
        if (pointerHeld) {
            closePending = true;
            return;
        }
        if (!launcherWindow.visible || launcherWindow.closing)
            return;
        launcherWindow.closing = true;
        if (contentLoader.item) {
            contentLoader.item.disarmGrab();
            contentLoader.item.dismiss();
        } else {
            launcherWindow.visible = false;
        }
        closeWatchdog.restart();
    }

    function releasePointer() {
        launcherWindow.pointerHeld = false;
        if (launcherWindow.closePending) {
            launcherWindow.closePending = false;
            launcherWindow.closeMenu();
        }
    }

    Timer {
        id: closeWatchdog
        interval: 800
        onTriggered: {
            if (launcherWindow.visible) {
                if (contentLoader.item)
                    contentLoader.item.disarmGrab();
                launcherWindow.closing = false;
                launcherWindow.visible = false;
            }
        }
    }

    Rectangle {
        id: launcherScrim
        z: -1
        anchors.fill: parent
        color: Theme.scrim
        opacity: 0

        NumberAnimation {
            id: scrimAnim
            target: launcherScrim
            property: "opacity"
            from: 0
            to: 0.35
            duration: Motion.duration(Motion.fastEffects)
            easing.type: Easing.OutCubic
        }
    }

    LazyLoader {
        id: contentLoader

        activeAsync: launcherWindow.visible

        function exit() {
            if (item) {
                item.disarmGrab();
                item.dismiss();
            } else
                launcherWindow.visible = false;
        }

        component: Component {
            Item {
                id: lazyContentRoot

                parent: launcherWindow.contentItem
                anchors.fill: parent

                HyprlandFocusGrab {
                    id: focusGrab
                    windows: [launcherWindow]
                    onCleared: launcherWindow.closeMenu()
                }

                function disarmGrab() {
                    focusGrab.active = false;
                }

                function dismiss() {
                    exitAnim.start();
                }

                Component.onCompleted: {
                    focusGrab.active = true;
                    searchField.forceActiveFocus();
                    enterAnim.start();
                }

                MouseArea {
                    id: backdrop
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onPressed: launcherWindow.pointerHeld = true
                    onReleased: {
                        launcherWindow.releasePointer();
                        launcherWindow.closeMenu();
                    }
                    onCanceled: launcherWindow.releasePointer()
                }

                Item {
                    id: cardCenter

                    readonly property real maxWidth: 640

                    width: Math.min(maxWidth, lazyContentRoot.width - 48)

                    height: cardColumn.implicitHeight
                    x: (lazyContentRoot.width - width) / 2
                    y: (lazyContentRoot.height - height) / 2

                    Behavior on height {
                        NumberAnimation {
                            duration: Motion.duration(Motion.standardSmall)
                            easing.type: Easing.OutCubic
                        }
                    }

                    opacity: 0
                    scale: 0.94
                    transformOrigin: Item.Center

                    ParallelAnimation {
                        id: enterAnim

                        NumberAnimation {
                            target: cardCenter
                            property: "opacity"
                            to: 1
                            duration: Motion.duration(Motion.standardSmall)
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: cardCenter
                            property: "scale"
                            to: 1
                            duration: Motion.duration(Motion.fastSpatial)
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.1
                        }
                    }

                    SequentialAnimation {
                        id: exitAnim

                        ParallelAnimation {
                            NumberAnimation {
                                target: cardCenter
                                property: "opacity"
                                to: 0
                                duration: Motion.duration(Motion.fastEffects)
                                easing.type: Easing.InCubic
                            }
                            NumberAnimation {
                                target: cardCenter
                                property: "scale"
                                to: 0.96
                                duration: Motion.duration(Motion.fastEffects)
                                easing.type: Easing.InCubic
                            }
                        }
                        ScriptAction {

                            script: launcherWindow.visible = false
                        }
                    }

                Rectangle {
                    id: card

                    anchors.fill: parent

                    radius: 16

                    color: Theme.surface_container_low
                    border.width: 1
                    border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.2)

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
                            if (listView.currentItem)
                                listView.currentItem.launch();
                            event.accepted = true;
                        }
                    }

                    Column {
                        id: cardColumn
                        width: parent.width

                        Item {
                            id: searchRow
                            width: parent.width
                            height: 56

                            Text {
                                id: searchIcon
                                anchors.left: parent.left
                                anchors.leftMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                text: "search"
                                color: Theme.on_surface_variant
                                opacity: 0.7
                                font {
                                    family: "Material Symbols Rounded"
                                    pixelSize: 24
                                }
                            }

                            TextField {
                                id: searchField
                                anchors.left: searchIcon.right
                                anchors.leftMargin: 16
                                anchors.right: clearButton.left
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                height: 48

                                font {
                                    family: "Google Sans"
                                    pixelSize: 22
                                    weight: Font.Normal
                                }
                                color: Theme.on_surface
                                selectionColor: Theme.primary_container
                                selectedTextColor: Theme.on_primary_container

                                placeholderText: "Search apps..."
                                placeholderTextColor: Qt.rgba(
                                    Theme.on_surface_variant.r,
                                    Theme.on_surface_variant.g,
                                    Theme.on_surface_variant.b,
                                    0.4
                                )

                                background: Item {}

                                leftPadding: 0
                                rightPadding: 8

                                onTextChanged: {
                                    ctrl.searchText = text;
                                    listView.currentIndex = 0;
                                    clearButton.visible = text.length > 0;
                                }

                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Escape) {
                                        if (text.length > 0) {
                                            text = "";
                                        } else {
                                            launcherWindow.closeMenu();
                                        }
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                                        if (listView.currentItem)
                                            listView.currentItem.launch();
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Down) {
                                        listView.incrementCurrentIndex();
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Up) {
                                        listView.decrementCurrentIndex();
                                        event.accepted = true;
                                    }
                                }
                            }

                            Rectangle {
                                id: clearButton
                                visible: false
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                width: 40
                                height: 40
                                radius: 20
                                color: clearMouse.containsMouse
                                    ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)
                                    : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "close"
                                    color: Theme.on_surface_variant
                                    opacity: 0.6
                                    font {
                                        family: "Material Symbols Rounded"
                                        pixelSize: 18
                                    }
                                }

                                MouseArea {
                                    id: clearMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        searchField.text = "";
                                        searchField.forceActiveFocus();
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.outline_variant
                            opacity: 0.2
                            visible: listView.count > 0
                        }

                        ListView {
                            id: listView
                            width: parent.width

                            height: Math.min(contentHeight, 300)
                            visible: count > 0
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            topMargin: 6
                            bottomMargin: 6
                            leftMargin: 6
                            rightMargin: 6

                            spacing: 2
                            highlightMoveDuration: 0
                            currentIndex: 0

                            model: ScriptModel {
                                values: launcherWindow.buildFilteredList()
                            }

                            delegate: LauncherDelegate {}

                            displaced: Transition {
                                NumberAnimation {
                                    properties: "x,y"
                                    duration: 180
                                    easing.type: Easing.OutCubic
                                }
                            }
                            add: Transition {
                                NumberAnimation {
                                    property: "opacity"
                                    from: 0
                                    to: 1
                                    duration: 140
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            height: visible ? 72 : 0
                            visible: listView.count === 0
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: "No matching applications"
                            color: Theme.on_surface_variant
                            opacity: 0.6
                            font {
                                family: "Google Sans"
                                pixelSize: 15
                            }
                        }
                    }
                }
            }
        }
    }
    }
}
