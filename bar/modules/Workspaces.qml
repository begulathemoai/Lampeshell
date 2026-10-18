import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.theme
import qs.bar.widgets
import qs.services

Rectangle {
    id: root

    property string targetMonitor: ""
    property bool vertical: false

    property bool windowVisible: true
    property bool isLoaded: false
    readonly property bool allowAnimations: isLoaded && windowVisible

    readonly property int animDurationShort: 150
    readonly property int dotHeight: Layout.s(28)
    readonly property int spacingAmount: Layout.s(8)

    property var iconCache: ({})

    function resolveIconSource(appClass, appTitle) {
        var lowerClass = (appClass || "").toLowerCase();
        var cacheKey = lowerClass !== "" ? lowerClass : ("title:" + appTitle);

        if (root.iconCache.hasOwnProperty(cacheKey))
            return root.iconCache[cacheKey];

        var exactTitle = (appTitle || "").trim().toLowerCase();
        var desktopEntry = null;

        if (lowerClass !== "") {

            desktopEntry = DesktopEntries.byId(appClass) || DesktopEntries.byId(lowerClass) || DesktopEntries.byId(lowerClass.replace(/_/g, "-"));

            var apps = DesktopEntries.applications.values;

            if (!desktopEntry) {
                for (var i = 0; i < apps.length; i++) {
                    if ((apps[i].startupClass || "").toLowerCase() === lowerClass) {
                        desktopEntry = apps[i];
                        break;
                    }
                }
            }

            if (!desktopEntry) {
                var uniqueIdMatch = lowerClass.match(/\d{4,}/);
                if (uniqueIdMatch) {
                    var numericId = uniqueIdMatch[0];
                    for (var k = 0; k < apps.length; k++) {
                        if (apps[k].id.includes(numericId)) {
                            desktopEntry = apps[k];
                            break;
                        }
                    }
                }
            }

            if (!desktopEntry && exactTitle !== "") {
                for (var j = 0; j < apps.length; j++) {
                    var appName = (apps[j].name || "").toLowerCase();
                    if (appName !== "" && (exactTitle === appName || exactTitle.startsWith(appName))) {
                        desktopEntry = apps[j];
                        break;
                    }
                }
            }

            if (!desktopEntry)
                desktopEntry = DesktopEntries.heuristicLookup(appClass);
        }

        var guesses = [];

        if (desktopEntry && desktopEntry.icon)
            guesses.push(desktopEntry.icon);

        if (appClass !== "") {
            guesses.push(appClass);
            guesses.push(lowerClass);
            guesses.push(lowerClass.replace(/_/g, "-"));

            if (lowerClass.includes("app"))
                guesses.push(lowerClass.replace("app", "icon"));

            var ignoreList = ["app", "desktop", "com", "org", "net", "io", "www", "bin"];
            var tokens = lowerClass.split(/[^a-z0-9]/).filter(t => t.length > 2 && !ignoreList.includes(t));

            for (var t = tokens.length - 1; t >= 0; t--)
                guesses.push(tokens[t]);
        }

        var resolved = Quickshell.iconPath("application-x-executable", true);
        for (var g = 0; g < guesses.length; g++) {
            var guess = guesses[g];
            if (!guess)
                continue;

            if (guess.startsWith("/")) {
                resolved = "file://" + guess;
                break;
            }

            var path = Quickshell.iconPath(guess, true);
            if (path && path !== "") {
                resolved = path;
                break;
            }
        }

        root.iconCache[cacheKey] = resolved;
        return resolved;
    }

    readonly property var sortedWorkspaces: {
        var ws = Hyprland.workspaces.values;
        return ws.filter(w => w.id >= 1 && w.monitor?.name === root.targetMonitor).sort((a, b) => a.id - b.id);
    }

    property int workspaceCount: 10

    readonly property var workspaceSlots: {
        const existing = {};
        const live = Hyprland.workspaces.values;
        for (let i = 0; i < live.length; i++) {
            const w = live[i];
            if (w && w.id >= 1)
                existing[w.id] = w;
        }

        const focusId = root.focusedWorkspace ? root.focusedWorkspace.id : -1;
        const slots = [];

        for (let n = 1; n <= root.workspaceCount; n++) {
            const ws = existing[n] ?? null;
            slots.push({
                id: n,
                focused: ws ? ws.focused === true : n === focusId,
                active: ws ? ws.active === true : false,

                monitor: ws?.monitor ?? { name: root.targetMonitor },
                toplevels: ws ? ws.toplevels : { values: [] },
                activate: function() {
                    if (ws && typeof ws.activate === "function") {
                        ws.activate();
                        return;
                    }

                    Hypr.focusWorkspace(n);
                }
            });
        }

        return slots;
    }

    readonly property var focusedWorkspace: currentMonitor ? currentMonitor.activeWorkspace : null

    readonly property var currentMonitor: {
        const mons = Hyprland.monitors.values;
        for (let i = 0; i < mons.length; i++) {
            if (mons[i].name === root.targetMonitor)
                return mons[i];
        }
        return null;
    }

    readonly property var activeLayout: root.vertical ? colLayout : rowLayout
    readonly property var activeRepeater: root.vertical ? colRepeater : rowRepeater

    readonly property var currentActiveDot: {
        if (!root.focusedWorkspace)
            return null;

        const rep = root.activeRepeater;
        if (!rep)
            return null;

        for (let i = 0; i < rep.count; i++) {
            let child = rep.itemAt(i);
            if (child && child.modelDataId === root.focusedWorkspace.id)
                return child;
        }
        return null;
    }

    implicitWidth: (root.vertical ? root.dotHeight : rowLayout.width) + Layout.s(16)
    implicitHeight: (root.vertical ? colLayout.height : root.dotHeight) + Layout.s(16)
    color: Theme.surface_container
    radius: Math.min(width, height) / 2

    Component.onCompleted: {

        Hypr.refreshAll();
        Qt.callLater(() => {
            root.isLoaded = true;
        });
    }

    Rectangle {
        id: slidingHighlight

        property real targetMain: {
            if (!currentActiveDot)
                return 0;

            const rep = root.activeRepeater;
            let tx = 0;

            for (let i = 0; i < rep.count; i++) {
                let child = rep.itemAt(i);
                if (!child)
                    continue;
                if (child === currentActiveDot)
                    break;
                if (child.isVisible)
                    tx += child.targetMain + root.spacingAmount;
            }
            return tx;
        }

        x: root.activeLayout.x + (root.vertical ? 0 : targetMain)
        y: root.activeLayout.y + (root.vertical ? targetMain : 0)
        width: currentActiveDot ? (root.vertical ? root.dotHeight : currentActiveDot.targetMain) : 0
        height: currentActiveDot ? (root.vertical ? currentActiveDot.targetMain : root.dotHeight) : 0

        topLeftRadius: width * 0.15
        topRightRadius: width * 0.9
        bottomRightRadius: width * 0.15
        bottomLeftRadius: width * 0.9

        color: currentActiveDot?.isFocused ? (Theme.primary) : (Theme.primary_container)

        Behavior on color {
            enabled: root.allowAnimations
            ColorAnimation {
                duration: root.animDurationShort
            }
        }

        Behavior on x {
            enabled: root.allowAnimations
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutBack
                easing.overshoot: 1.5
            }
        }

        Behavior on y {
            enabled: root.allowAnimations
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutBack
                easing.overshoot: 1.5
            }
        }

        Behavior on width {
            enabled: root.allowAnimations
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutBack
                easing.overshoot: 1.5
            }
        }

        Behavior on height {
            enabled: root.allowAnimations
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutBack
                easing.overshoot: 1.5
            }
        }
    }

    Row {
        id: rowLayout
        visible: !root.vertical
        anchors.centerIn: parent
        spacing: root.spacingAmount

        Repeater {
            id: rowRepeater
            model: ScriptModel {
                values: root.workspaceSlots
            }
            delegate: dotComponent
        }
    }

    Column {
        id: colLayout
        visible: root.vertical
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.spacingAmount

        Repeater {
            id: colRepeater
            model: ScriptModel {
                values: root.workspaceSlots
            }
            delegate: dotComponent
        }
    }

    Component {
        id: dotComponent

        Item {
            id: workspaceDot

            readonly property int modelDataId: modelData.id
            readonly property bool isVisible: modelData.id >= 1 && modelData.monitor?.name === root.targetMonitor
            readonly property bool isFocused: modelData.focused
            readonly property bool isActive: modelData.active
            readonly property var toplevelValues: modelData.toplevels.values
            readonly property int windowCount: toplevelValues.length
            readonly property bool hasWindows: windowCount > 0

            visible: isVisible

            readonly property real iconExtent: root.vertical ? iconStripVertical.implicitHeight : iconStripHorizontal.implicitWidth

            readonly property real targetMain: {
                if (!isVisible)
                    return 0;
                if (!hasWindows)
                    return isFocused || isActive ? Layout.s(36) : (dotHover.hovered ? Layout.s(24) : Layout.s(16));
                let padding = isFocused || isActive ? Layout.s(20) : Layout.s(16);
                let minimum = isFocused || isActive ? Layout.s(48) : (dotHover.hovered ? Layout.s(44) : Layout.s(36));
                return Math.max(minimum, iconExtent + padding);
            }

            width: root.vertical ? root.dotHeight : targetMain
            height: root.vertical ? targetMain : root.dotHeight

            Behavior on width {
                enabled: root.allowAnimations
                NumberAnimation {
                    duration: 280
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.5
                }
            }

            Behavior on height {
                enabled: root.allowAnimations
                NumberAnimation {
                    duration: 280
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.5
                }
            }

            transform: Scale {
                origin.x: workspaceDot.width / 2
                origin.y: workspaceDot.height / 2
                xScale: dotTap.pressed ? 1.04 : 1.0
                yScale: dotTap.pressed ? 0.84 : 1.0

                Behavior on xScale {
                    enabled: root.allowAnimations
                    NumberAnimation {
                        duration: dotTap.pressed ? 100 : 150
                        easing.type: dotTap.pressed ? Easing.OutQuad : Easing.OutBack
                        easing.overshoot: 1.1
                    }
                }
                Behavior on yScale {
                    enabled: root.allowAnimations
                    NumberAnimation {
                        duration: dotTap.pressed ? 100 : 150
                        easing.type: dotTap.pressed ? Easing.OutQuad : Easing.OutBack
                        easing.overshoot: 1.1
                    }
                }
            }

            Rectangle {
                id: inactivePill
                anchors.fill: parent
                radius: Math.min(width, height) / 2
                opacity: (workspaceDot.isFocused || workspaceDot.isActive) ? 0.0 : 1.0

                Behavior on opacity {
                    enabled: root.allowAnimations
                    NumberAnimation {
                        duration: 150
                    }
                }

                color: dotHover.hovered ? (Theme.secondary_container) : (Theme.surface_container_high)

                Behavior on color {
                    enabled: root.allowAnimations
                    ColorAnimation {
                        duration: root.animDurationShort
                    }
                }
            }

            Rectangle {
                id: stateLayer
                anchors.fill: parent
                radius: Math.min(width, height) / 2

                color: (workspaceDot.isFocused || workspaceDot.isActive) ? (Theme.on_primary) : (Theme.on_surface)
                opacity: dotTap.pressed ? 0.10 : (dotHover.hovered ? 0.08 : 0.0)

                Behavior on opacity {
                    enabled: root.allowAnimations
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }

                Ripple {
                    id: dotRipple
                    cornerRadius: stateLayer.radius
                    rippleColor: stateLayer.color
                }
            }

            Component {
                id: iconSlotComponent

                Item {
                    id: iconSlot
                    visible: index < 3
                    width: visible ? Layout.s(18) : 0
                    height: Layout.s(18)

                    readonly property string appClass: modelData.class ?? modelData.initialClass ?? modelData.lastIpcObject?.class ?? ""
                    readonly property string appTitle: modelData.title ?? ""

                    readonly property string iconSource: root.resolveIconSource(appClass, appTitle)
                    readonly property string fallbackLetter: {
                        var name = appClass !== "" ? appClass : appTitle;
                        return name.length > 0 ? name.charAt(0).toUpperCase() : "?";
                    }

                    Rectangle {
                        id: roundMask
                        anchors.centerIn: parent
                        width: Layout.s(18)
                        height: Layout.s(18)
                        radius: Layout.s(9)
                        color: Theme.shadow
                        visible: false
                        layer.enabled: true
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: Layout.s(19)
                        height: Layout.s(19)
                        radius: Layout.s(9.5)
                        color: "transparent"
                        border.width: 1.5
                        border.color: (workspaceDot.isFocused || workspaceDot.isActive) ? (Theme.primary) : (Theme.surface_container_high)

                        Behavior on border.color {
                            enabled: root.allowAnimations
                            ColorAnimation {
                                duration: root.animDurationShort
                            }
                        }
                    }

                    Rectangle {
                        id: fallbackBadge
                        anchors.fill: parent
                        radius: height / 2
                        color: (workspaceDot.isFocused || workspaceDot.isActive) ? (Theme.on_primary) : (Theme.on_surface_variant)
                        opacity: (iconImg.status === Image.Ready && iconImg.source != "") ? 0.0 : 0.3
                        visible: opacity > 0

                        Behavior on opacity {
                            enabled: root.allowAnimations
                            NumberAnimation {
                                duration: 100
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: iconSlot.fallbackLetter
                            color: (workspaceDot.isFocused || workspaceDot.isActive) ? (Theme.primary) : (Theme.surface_container)
                            font {
                                family: "Google Sans"
                                pixelSize: Layout.ts(10)
                                weight: Font.Bold
                            }
                        }
                    }

                    IconImage {
                        id: iconImg
                        anchors.fill: parent
                        source: iconSlot.iconSource
                        smooth: true
                        visible: false
                    }

                    MultiEffect {
                        anchors.fill: iconImg
                        source: iconImg

                        maskEnabled: true
                        maskSource: roundMask
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1.0

                        saturation: -0.3
                        colorizationColor: (workspaceDot.isFocused || workspaceDot.isActive) ? (Theme.on_primary) : (Theme.on_surface_variant)
                        colorization: 0.3

                        opacity: (iconImg.status === Image.Ready && iconImg.source != "") ? 1.0 : 0.0

                        Behavior on opacity {
                            enabled: root.allowAnimations
                            NumberAnimation {
                                duration: 100
                            }
                        }
                    }
                }
            }

            Row {
                id: iconStripHorizontal
                anchors.centerIn: parent
                spacing: -Layout.s(8)
                visible: !root.vertical && workspaceDot.hasWindows

                Repeater {
                    model: workspaceDot.toplevelValues
                    delegate: iconSlotComponent
                }

                Rectangle {
                    visible: workspaceDot.windowCount > 3
                    width: Layout.s(18)
                    height: Layout.s(18)
                    radius: Layout.s(9)
                    color: "transparent"
                    border.color: (workspaceDot.isFocused || workspaceDot.isActive) ? (Theme.on_primary) : (Theme.on_surface_variant)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "+" + (workspaceDot.windowCount - 3)
                        color: (workspaceDot.isFocused || workspaceDot.isActive) ? (Theme.on_primary) : (Theme.on_surface_variant)
                        font {
                            family: "Google Sans"
                            pixelSize: Layout.ts(9)
                            weight: Font.Bold
                        }
                    }
                }
            }

            Column {
                id: iconStripVertical
                anchors.centerIn: parent
                spacing: -Layout.s(8)
                visible: root.vertical && workspaceDot.hasWindows

                Repeater {
                    model: workspaceDot.toplevelValues
                    delegate: iconSlotComponent
                }

                Rectangle {
                    visible: workspaceDot.windowCount > 3
                    width: Layout.s(18)
                    height: Layout.s(18)
                    radius: Layout.s(9)
                    color: "transparent"
                    border.color: (workspaceDot.isFocused || workspaceDot.isActive) ? (Theme.on_primary) : (Theme.on_surface_variant)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "+" + (workspaceDot.windowCount - 3)
                        color: (workspaceDot.isFocused || workspaceDot.isActive) ? (Theme.on_primary) : (Theme.on_surface_variant)
                        font {
                            family: "Google Sans"
                            pixelSize: Layout.ts(9)
                            weight: Font.Bold
                        }
                    }
                }
            }

            Rectangle {
                anchors.centerIn: parent
                visible: !workspaceDot.hasWindows

                width: workspaceDot.isFocused ? Layout.s(8) : Layout.s(6)
                height: width
                radius: width / 2

                color: (workspaceDot.isFocused || workspaceDot.isActive) ? (Theme.on_primary) : (Theme.on_surface_variant)
                opacity: workspaceDot.isFocused ? 1.0 : (dotHover.hovered ? 1.0 : 0.6)

                Behavior on width {
                    enabled: root.allowAnimations
                    NumberAnimation {
                        duration: 280
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.5
                    }
                }
            }

            TapHandler {
                id: dotTap
                margin: 8
                onPressedChanged: if (pressed)
                    dotRipple.trigger(point.position.x, point.position.y)
                onTapped: modelData.activate()
            }

            HoverHandler {
                id: dotHover
                margin: 8
                cursorShape: Qt.PointingHandCursor
            }
        }
    }
}
