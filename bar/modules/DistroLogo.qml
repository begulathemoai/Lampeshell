import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.theme
import qs.services

Item {
    id: root

    property bool vertical: false

    readonly property string prettyName: osRelease.prettyName
    readonly property string logoKey: osRelease.logo !== "" ? osRelease.logo : osRelease.osId

    implicitWidth: Layout.s(24)
    implicitHeight: Layout.s(24)

    FileView {
        id: osRelease

        path: "/etc/os-release"

        property string logo: ""
        property string osId: ""
        property string prettyName: ""

        onLoaded: {
            const lines = text().split("\n");
            const fd = key => {
                const line = lines.find(l => l.startsWith(key + "="));
                return line ? line.split("=").slice(1).join("=").replace(/^"|"$/g, "") : "";
            };
            osRelease.logo = fd("LOGO");
            osRelease.osId = fd("ID");
            osRelease.prettyName = fd("PRETTY_NAME");
        }
    }

    readonly property var logoCandidates: {
        const names = [];
        if (osRelease.logo)
            names.push(osRelease.logo);
        if (osRelease.osId && osRelease.osId !== osRelease.logo)
            names.push(osRelease.osId);
        names.push("distributor-logo");

        const urls = [];
        for (const n of names) {
            const themed = Quickshell.iconPath(n, true);
            if (themed)
                urls.push(themed);
            urls.push("file:///usr/share/pixmaps/" + n + ".svg");
            urls.push("file:///usr/share/pixmaps/" + n + ".png");
            urls.push("file:///usr/share/icons/" + n + ".svg");
            urls.push("file:///usr/share/icons/" + n + ".png");
        }
        return urls;
    }

    property int logoIndex: 0

    onLogoCandidatesChanged: logoIndex = 0

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: LauncherState.requestToggle()
    }

    Loader {
        asynchronous: true
        anchors.centerIn: parent
        active: logoImage.status !== Image.Ready
        sourceComponent: Text {
            text: root.prettyName.length > 0 ? root.prettyName.charAt(0).toUpperCase() : "?"
            color: Theme.tertiary

            font {
                family: "Google Sans"
                pixelSize: Layout.ts(14)
                weight: Font.Bold
            }
        }
    }

    Image {
        id: logoImage

        anchors.centerIn: parent
        width: root.width
        height: root.height
        sourceSize: Qt.size(width * 2, height * 2)
        source: root.logoIndex < root.logoCandidates.length ? root.logoCandidates[root.logoIndex] : ""
        asynchronous: true
        visible: false

        onStatusChanged: {
            if (status === Image.Error && root.logoIndex < root.logoCandidates.length - 1)
                root.logoIndex++;
        }
    }

    MultiEffect {
        anchors.fill: logoImage
        source: logoImage
        colorization: 1.0
        colorizationColor: Theme.tertiary
        visible: logoImage.status === Image.Ready
    }
}
