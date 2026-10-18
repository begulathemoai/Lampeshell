import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import "../../theme"

PanelWindow {
    id: emojiWindow

    implicitWidth: 550
    implicitHeight: 640
    color: "transparent"
    visible: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "emoji_overlay"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: -1
    anchors.bottom: true
    margins.bottom: Layout.bottomBarHeight + Layout.s(140)

    EmojiBackend {
        id: ctrl

        onOpenMenuRequested: {
            if (emojiWindow.visible) {
                closeMenu();
                return;
            }
            ctrl.triggerSearch();
            ctrl.searchText = "";
            ctrl.selectionBuffer = "";
            ctrl.currentCategory = "Recents";

            emojiWindow.closing = false;
            closeWatchdog.stop();
            emojiWindow.visible = true;
            if (contentLoader.item)
                contentLoader.item.playEnter();
        }

        onCloseMenuRequested: {
            closeMenu();
        }
    }

    property bool closing: false

    function closeMenu() {
        if (!emojiWindow.visible || emojiWindow.closing)
            return;
        emojiWindow.closing = true;
        if (contentLoader.item) {
            contentLoader.item.disarmGrab();
            contentLoader.item.dismiss();
        } else {
            emojiWindow.visible = false;
        }
        closeWatchdog.restart();
        ctrl.commitRecents();
    }

    function disarmGrab() {
        if (contentLoader.item)
            contentLoader.item.disarmGrab();
        emojiWindow.visible = false;
    }

    Timer {
        id: closeWatchdog
        interval: 800
        onTriggered: {
            if (emojiWindow.visible) {
                if (contentLoader.item)
                    contentLoader.item.disarmGrab();
                emojiWindow.closing = false;
                emojiWindow.visible = false;
            }
        }
    }

    function processSelection(emojiChar, isShift) {
        ctrl.processSelection(emojiChar, isShift);
    }

    LazyLoader {
        id: contentLoader

        activeAsync: true

        component: Component {
            Item {
                id: delegateContainer

                parent: emojiWindow.contentItem

                property real driftOffset: 12

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.leftMargin: 30
                anchors.rightMargin: 30
                anchors.topMargin: 30 + driftOffset
                anchors.bottomMargin: 30 - driftOffset

                opacity: 0
                scale: 0.86
                transformOrigin: Item.Bottom

                ParallelAnimation {
                    id: enterAnim

                    NumberAnimation {
                        target: delegateContainer
                        property: "opacity"
                        to: 1
                        duration: Motion.duration(Motion.standard)
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: delegateContainer
                        property: "scale"
                        to: 1
                        duration: Motion.duration(Motion.slowSpatial)
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.1
                    }
                    NumberAnimation {
                        target: delegateContainer
                        property: "driftOffset"
                        to: 0
                        duration: Motion.duration(Motion.slowSpatial)
                        easing.type: Easing.OutCubic
                    }
                }

                SequentialAnimation {
                    id: exitAnim

                    ParallelAnimation {
                        NumberAnimation {
                            target: delegateContainer
                            property: "opacity"
                            to: 0
                            duration: Motion.duration(Motion.standard)
                            easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            target: delegateContainer
                            property: "scale"
                            to: 0.94
                            duration: Motion.duration(Motion.standard)
                            easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            target: delegateContainer
                            property: "driftOffset"
                            to: 8
                            duration: Motion.duration(Motion.standard)
                            easing.type: Easing.InCubic
                        }
                    }
                    ScriptAction {
                        script: ctrl.commitRecents(), emojiWindow.visible = false
                    }
                }

                function playEnter() {
                    delegateContainer.opacity = 0;
                    delegateContainer.scale = 0.86;
                    delegateContainer.driftOffset = 12;
                    enterAnim.restart();
                }

                function dismiss() {
                    exitAnim.start();
                }

                function updateEmojiLabel() {
                    ctrl.currentEmojiName = gridView.currentItem ? gridView.currentItem.emojiName : "";
                }

                function navigateDown() {
                    gridView.moveCurrentIndexDown();
                    updateEmojiLabel();
                }
                function navigateUp() {
                    gridView.moveCurrentIndexUp();
                    updateEmojiLabel();
                }
                function navigateLeft() {
                    gridView.moveCurrentIndexLeft();
                    updateEmojiLabel();
                }
                function navigateRight() {
                    gridView.moveCurrentIndexRight();
                    updateEmojiLabel();
                }
                function selectCurrent(shiftHeld) {
                    if (gridView.currentItem) {
                        ctrl.processSelection(gridView.currentItem.emojiChar, shiftHeld);
                    }
                }

                HyprlandFocusGrab {
                    id: focusGrab
                    windows: [emojiWindow]
                    onCleared: emojiWindow.closeMenu()
                }

                function disarmGrab() {
                    focusGrab.active = false;
                }

                Component.onCompleted: {
                    focusGrab.active = true;
                    mainUi.forceActiveFocus();
                    updateEmojiLabel();
                }
                Rectangle {
                    id: shadowCaster
                    anchors.fill: mainUi
                    radius: 28
                    color: Theme.shadow
                    visible: false
                }

                MultiEffect {
                    anchors.fill: shadowCaster
                    source: shadowCaster
                    shadowEnabled: true
                    shadowBlur: 1.0
                    shadowColor: Qt.rgba(Theme.shadow.r, Theme.shadow.g, Theme.shadow.b, 0.38)
                    shadowVerticalOffset: 12
                }

                Rectangle {
                    id: mainUi
                    anchors.fill: parent
                    color: Theme.surface
                    radius: 28
                    clip: true
                    focus: true

                    Keys.onPressed: event => {
                        switch (event.key) {
                        case Qt.Key_Escape:
                            emojiWindow.closeMenu();
                            event.accepted = true;
                            break;
                        case Qt.Key_Tab:
                            ctrl.cycleCategory();
                            event.accepted = true;
                            break;
                        case Qt.Key_Down:
                        case Qt.Key_J:
                            navigateDown();
                            event.accepted = true;
                            break;
                        case Qt.Key_Up:
                        case Qt.Key_K:
                            navigateUp();
                            event.accepted = true;
                            break;
                        case Qt.Key_Left:
                        case Qt.Key_H:
                            navigateLeft();
                            event.accepted = true;
                            break;
                        case Qt.Key_Right:
                        case Qt.Key_L:
                            navigateRight();
                            event.accepted = true;
                            break;
                        case Qt.Key_Enter:
                        case Qt.Key_Return:
                            selectCurrent((event.modifiers & Qt.ShiftModifier) !== 0);
                            event.accepted = true;
                            break;
                        case Qt.Key_Slash:
                            searchField.forceActiveFocus();
                            event.accepted = true;
                            break;
                        }
                    }

                    Item {
                        id: headerArea
                        width: parent.width
                        height: 64
                        anchors.top: parent.top

                        Text {
                            id: headerTitle
                            anchors {
                                top: parent.top
                                left: parent.left
                                margins: 24
                                topMargin: 20
                            }
                            text: "Emojis"
                            color: Theme.on_surface
                            font {
                                family: "Google Sans"
                                pixelSize: 26
                                weight: Font.Medium
                            }
                        }

                        Rectangle {
                            id: clearRecentsBtn
                            anchors {
                                right: parent.right
                                rightMargin: 24
                                verticalCenter: headerTitle.verticalCenter
                            }
                            width: 36
                            height: 36
                            radius: 18
                            color: clearMouseArea.containsMouse ? Theme.surface_container_highest : "transparent"
                            visible: ctrl.currentCategory === "Recents" && ctrl.recentItems.length > 0

                            Text {
                                anchors.centerIn: parent
                                text: "delete"
                                font {
                                    family: "Material Symbols Rounded"
                                    pixelSize: 26
                                    bold: true
                                }
                                color: Theme.critical
                            }

                            MouseArea {
                                id: clearMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ctrl.clearRecents()
                            }
                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                        }
                    }

                    TextField {
                        id: searchField
                        anchors {
                            top: headerArea.bottom
                            left: parent.left
                            right: parent.right
                            margins: 16
                            topMargin: 4
                        }
                        height: 56
                        leftPadding: 52
                        rightPadding: text !== "" ? 48 : 16
                        font {
                            family: "Google Sans"
                            pixelSize: 17
                        }
                        color: Theme.on_surface
                        selectionColor: Theme.primary_container
                        selectedTextColor: Theme.on_primary_container
                        placeholderText: "Search"
                        placeholderTextColor: Theme.on_surface_variant

                        background: Rectangle {
                            color: searchField.activeFocus ? Theme.surface_container_highest : Theme.surface_container_high
                            radius: height / 2
                            border.width: searchField.activeFocus ? 2 : 1
                            border.color: searchField.activeFocus ? Theme.primary : Theme.outline_variant
                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }

                            Text {
                                anchors {
                                    left: parent.left
                                    leftMargin: 20
                                    verticalCenter: parent.verticalCenter
                                }
                                text: "search"
                                font {
                                    family: "Material Symbols Rounded"
                                    pixelSize: 24
                                }
                                color: searchField.activeFocus ? Theme.primary : Theme.on_surface_variant
                            }
                        }

                        onTextChanged: ctrl.searchText = text

                        Keys.onPressed: event => {
                            switch (event.key) {
                            case Qt.Key_Down:
                                navigateDown();
                                event.accepted = true;
                                break;
                            case Qt.Key_Up:
                                navigateUp();
                                event.accepted = true;
                                break;
                            case Qt.Key_Left:
                                navigateLeft();
                                event.accepted = true;
                                break;
                            case Qt.Key_Right:
                                navigateRight();
                                event.accepted = true;
                                break;
                            case Qt.Key_Tab:
                                ctrl.cycleCategory();
                                event.accepted = true;
                                break;
                            case Qt.Key_Enter:
                            case Qt.Key_Return:
                                selectCurrent((event.modifiers & Qt.ShiftModifier) !== 0);
                                event.accepted = true;
                                break;
                            case Qt.Key_Escape:
                                mainUi.forceActiveFocus();
                                event.accepted = true;
                                break;
                            }
                        }
                    }

                    Item {
                        id: categoryTabsContainer
                        anchors {
                            top: searchField.bottom
                            left: parent.left
                            right: parent.right
                            leftMargin: 16
                            rightMargin: 16
                            topMargin: 8
                        }
                        height: 48

                        Row {
                            anchors {
                                top: parent.top
                                bottom: parent.bottom
                                horizontalCenter: parent.horizontalCenter
                            }
                            spacing: 12

                            Repeater {
                                model: ctrl.categories

                                Rectangle {
                                    property bool isSelected: modelData === ctrl.currentCategory
                                    height: 36
                                    width: tabText.width + 32
                                    anchors.verticalCenter: parent.verticalCenter
                                    radius: 18
                                    color: isSelected ? Theme.primary : Theme.surface_container_high
                                    border {
                                        width: isSelected ? 0 : 1
                                        color: Theme.outline_variant
                                    }

                                    Text {
                                        id: tabText
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: isSelected ? Theme.on_primary : Theme.on_surface_variant
                                        font {
                                            family: "Google Sans"
                                            pixelSize: 14
                                            weight: isSelected ? Font.DemiBold : Font.Medium
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (searchField.text !== "")
                                                searchField.text = "";
                                            ctrl.currentCategory = modelData;
                                        }
                                    }
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        id: listContainer
                        anchors {
                            top: categoryTabsContainer.bottom
                            bottom: footer.top
                            left: parent.left
                            right: parent.right
                            topMargin: 8
                        }

                        GridView {
                            id: gridView
                            anchors {
                                top: parent.top
                                bottom: parent.bottom
                                horizontalCenter: parent.horizontalCenter
                            }
                            width: Math.floor((parent.width - 44) / cellWidth) * cellWidth
                            topMargin: 12
                            bottomMargin: 24
                            cellWidth: 60
                            cellHeight: 60
                            model: ctrl.filteredItems
                            clip: true
                            highlightMoveDuration: 120
                            highlightFollowsCurrentItem: true
                            onCurrentIndexChanged: updateEmojiLabel()

                            reuseItems: true
                            cacheBuffer: 600
                            displayMarginBeginning: 60
                            displayMarginEnd: 60

                            delegate: EmojiDelegate {}
                        }

                        Rectangle {
                            anchors {
                                bottom: parent.bottom
                                left: parent.left
                                right: parent.right
                            }
                            height: 48
                            gradient: Gradient {
                                GradientStop {
                                    position: 0.0
                                    color: "transparent"
                                }
                                GradientStop {
                                    position: 1.0
                                    color: Theme.surface_container_lowest
                                }
                            }
                        }
                    }

                    Item {
                        id: footer
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                            right: parent.right
                        }
                        height: 64

                        Rectangle {
                            anchors.fill: parent
                            color: Theme.surface_container_low
                            radius: 28
                            Rectangle {
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                    right: parent.right
                                }
                                height: 25
                                color: Theme.surface_container_low
                            }
                        }

                        Rectangle {
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                            }
                            height: 1
                            color: Theme.outline_variant
                            opacity: 0.5
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 8
                                Text {
                                    text: ctrl.selectionBuffer
                                    visible: ctrl.selectionBuffer !== ""
                                    anchors.verticalCenter: parent.verticalCenter
                                    font {
                                        family: "Noto Color Emoji"
                                        pixelSize: 18
                                    }
                                }
                                Text {
                                    text: ctrl.selectionBuffer !== "" ? ("+ " + (ctrl.currentEmojiName || "")) : (ctrl.currentEmojiName || "Select an emoji")
                                    color: Theme.on_surface_variant
                                    anchors.verticalCenter: parent.verticalCenter
                                    font {
                                        family: "Google Sans Medium"
                                        pixelSize: 15
                                    }
                                }
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "[Tab] Switch • [Enter] Select • [Shift] Multi • [Esc] Close"
                                color: Theme.on_surface_variant
                                opacity: 0.6
                                font {
                                    family: "Google Sans"
                                    pixelSize: 11
                                    weight: Font.Medium
                                }
                            }
                        }
                    }

                    Text {
                        id: emptyMessage
                        anchors.centerIn: listContainer
                        text: ctrl.currentCategory === "Recents" && ctrl.recentItems.length === 0 ? "No recent emojis" : "No emojis found 🥲"
                        visible: ctrl.filteredItems.length === 0
                        color: Theme.on_surface_variant
                        font {
                            family: "Google Sans Medium"
                            pixelSize: 18
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        radius: 28
                        border {
                            width: 1
                            color: Theme.outline_variant
                        }
                        z: 99
                    }
                }
            }
        }
    }
}
