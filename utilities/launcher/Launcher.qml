import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import "../../theme"

PanelWindow {
    id: launcherWindow

    // Add any apps you want to hide to this list
    property var hiddenKeywords: ["avahi", "uuctl", "bssh", "bvnc"]

    // Full-screen so the launcher can dim the desktop behind it, the way a
    // Spotlight-style overlay does. The card is centred inside this surface.
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

        // Exact match
        if (textLower === queryLower)
            return 1000;

        // Full string starts with query
        if (textLower.startsWith(queryLower))
            return 800;

        // Any word in the string starts with query
        var words = textLower.split(/[\s\-_]+/);
        for (var i = 0; i < words.length; i++) {
            if (words[i].startsWith(queryLower))
                return 600;
        }

        // single/double letter matches polluting short queries
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
        var allApps = DesktopEntries.applications.values;
        var query = ctrl.searchText.trim();
        var queryLower = query.toLowerCase();

        if (query === "") {
            // No query: show all apps, but completely hide any app matching hiddenKeywords
            return allApps.filter(app => !launcherWindow.isHiddenApp(app.name)).sort((a, b) => (a.name || "").localeCompare(b.name || ""));
        }

        // Check if the user's search explicitly contains any of the hidden keywords
        var isSearchingHidden = hiddenKeywords.some(keyword => queryLower.includes(keyword));
        var scored = [];

        for (var i = 0; i < allApps.length; i++) {
            var entry = allApps[i];

            // Hide apps matching hiddenKeywords unless explicitly searched for
            if (launcherWindow.isHiddenApp(entry.name) && !isSearchingHidden) {
                continue;
            }

            var best = scoreMatch(entry.name, query);

            // Check generic name (e.g., "Web Browser")
            if (entry.genericName) {
                var s = scoreMatch(entry.genericName, query);
                if (s >= 200)
                    best = Math.max(best, s - 50);
            }

            // Check comments
            if (entry.comment) {
                var s = scoreMatch(entry.comment, query);
                if (s >= 200)
                    best = Math.max(best, s - 100);
            }

            // Check keywords
            if (entry.keywords) {
                for (var j = 0; j < entry.keywords.length; j++) {
                    var s = scoreMatch(entry.keywords[j], query);
                    if (s >= 200)
                        best = Math.max(best, s - 20); // High weight for exact alias hits
                }
            }

            // Check the executable command
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

    // Metrolist does not tear the overlay down instantly: it fades the card out
    // over ~180ms and only then drops the surface, which stops the dismissal
    // reading as a snap.
    property bool closing: false

    function openMenu() {
        ctrl.searchText = "";
        closing = false;
        launcherWindow.visible = true; // Triggers UI build
    }

    function closeMenu() {
        if (!launcherWindow.visible || launcherWindow.closing)
            return;
        launcherWindow.closing = true;
        contentLoader.exit();
    }

    /**
     * Floating search, modelled on Metrolist's desktop FloatingSearchOverlay.
     *
     * The shape of it: a dimmed scrim across the whole screen, one centred card
     * (max 640 wide, 16 radius, surfaceContainerHigh, hairline border, deep
     * shadow), a search row at the top, a hairline divider, then results that
     * cap at a fixed height and the card grows and shrinks with them.
     *
     * There is no banner and no footer - the field is the hero and the results
     * are the only other thing in the panel.
     */
    LazyLoader {
        id: contentLoader

        activeAsync: launcherWindow.visible

        function exit() {
            if (item)
                item.dismiss();
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

                // Launched through the loader, which only knows about this item.
                function dismiss() {
                    cardCenter.dismiss();
                }

                Component.onCompleted: {
                    focusGrab.active = true;
                    searchField.forceActiveFocus();
                    enterAnim.start();
                }

                // Click-catcher only. Metrolist dims the desktop behind its
                // overlay; this shell does not, but clicks outside the card
                // still dismiss, so something has to own that area.
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: launcherWindow.closeMenu()
                }

                // --- Card ---
                Item {
                    id: cardCenter

                    readonly property real maxWidth: 640

                    width: Math.min(maxWidth, lazyContentRoot.width - 48)
                    // Height follows the column's implicit height, and animates
                    // as results come and go - Metrolist's animateContentSize.
                    //
                    // Deliberately not `card.height`: the card is anchored to
                    // fill this item, so binding the other way round is a
                    // circular binding and the whole panel collapses to zero.
                    height: cardColumn.implicitHeight
                    x: (lazyContentRoot.width - width) / 2
                    y: (lazyContentRoot.height - height) / 2

                    Behavior on height {
                        NumberAnimation {
                            duration: 240
                            easing.type: Easing.OutCubic
                        }
                    }

                    // Enter and exit transform, so the card itself stays a plain
                    // centred rectangle.
                    opacity: 0
                    scale: 0.90
                    transformOrigin: Item.Center

                    function dismiss() {
                        exitAnim.start();
                    }

                    SequentialAnimation {
                        id: exitAnim

                        ParallelAnimation {
                            NumberAnimation {
                                target: cardCenter
                                property: "opacity"
                                to: 0
                                duration: 180
                                easing.type: Easing.InCubic
                            }
                            NumberAnimation {
                                target: cardCenter
                                property: "scale"
                                to: 0.96
                                duration: 180
                                easing.type: Easing.InCubic
                            }
                        }
                        ScriptAction {
                            // Surface is only torn down once the fade is done.
                            script: launcherWindow.visible = false
                        }
                    }

                Rectangle {
                    id: card

                    anchors.fill: parent

                    radius: 16
                    // Material's surfaceBright rather than a container tone: on
                    // a dark scheme it sits above every surface_container step,
                    // which is what makes the card read as "above" the desktop.
                    color: Theme.surface_bright
                    border.width: 1
                    border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.2)

                    // No shadow: the previous rig (a MultiEffect reading an
                    // invisible rounded rect) filled the whole card with a
                    // translucent black box whenever its source failed to
                    // resolve, which read as an opaque black background. A flat
                    // hairline-bordered card is the safer modelling of the same
                    // surface.

                    // Enter: fade + scale up from 0.90 + rise, with the slight
                    // overshoot of a spring rather than a flat tween.
                    ParallelAnimation {
                        id: enterAnim

                        NumberAnimation {
                            target: cardCenter
                            property: "opacity"
                            to: 1
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: cardCenter
                            property: "scale"
                            to: 1
                            duration: 340
                            easing.type: Easing.OutBack
                        }
                    }

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

                        // --- Search row ---
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
                                    0.4 // Metrolist's placeholder sits back at 40%.
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

                            // Clear button, only once there is something to clear.
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

                        // --- Divider ---
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.outline_variant
                            opacity: 0.2
                            visible: listView.count > 0
                        }

                        // --- Results ---
                        ListView {
                            id: listView
                            width: parent.width
                            // Caps the panel height; the card shrinks back down
                            // when there are few or no results.
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
