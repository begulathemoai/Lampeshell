import QtQuick
import qs.theme
import qs.services

Item {
    id: root

    implicitWidth: Layout.s(828)
    implicitHeight: Layout.s(470)

    readonly property var player: Players.active

    function fmt(seconds) {
        if (!seconds || seconds <= 0 || isNaN(seconds))
            return "0:00";
        const s = Math.floor(seconds % 60);
        const m = Math.floor((seconds / 60) % 60);
        const h = Math.floor(seconds / 3600);
        const mm = h > 0 ? String(m).padStart(2, "0") : String(m);
        return (h > 0 ? h + ":" : "") + mm + ":" + String(s).padStart(2, "0");
    }

    Column {
        anchors.centerIn: parent
        visible: !root.player
        spacing: Layout.s(12)

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Layout.s(96)
            height: Layout.s(96)
            radius: width / 2
            color: Theme.primary_container

            Text {
                anchors.centerIn: parent
                text: "queue_music"
                color: Theme.on_primary_container
                font {
                    family: Layout.fontIcons
                    pixelSize: Layout.s(44)
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Nothing playing"
            color: Theme.on_surface
            font {
                family: Layout.fontSans
                pixelSize: Layout.s(18)
                weight: Font.Medium
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Play something for it to show up here!"
            color: Theme.on_surface_variant
            font {
                family: Layout.fontSans
                pixelSize: Layout.s(13)
            }
        }
    }

    Row {
        anchors.fill: parent
        anchors.margins: Layout.s(16)
        spacing: Layout.s(28)
        visible: root.player !== null

        Rectangle {
            id: artFrame

            width: Layout.s(280)
            height: Layout.s(280)
            anchors.verticalCenter: parent.verticalCenter
            radius: Layout.s(24)
            color: Theme.surface_container_high
            clip: true

            Rectangle {
                anchors.fill: parent
                visible: !artImage.visible
                color: Theme.surface_container_high

                Text {
                    anchors.centerIn: parent
                    text: "music_note"
                    color: Theme.on_surface_variant
                    font {
                        family: Layout.fontIcons
                        pixelSize: Layout.s(64)
                    }
                }
            }

            Image {
                id: artImage
                anchors.fill: parent
                source: root.player ? (root.player.trackArtUrl ?? "") : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }
        }

        Column {
            width: parent.width - artFrame.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: Layout.s(10)

            Text {
                width: parent.width
                text: root.player ? (root.player.identity ?? "") : ""
                color: Theme.primary
                elide: Text.ElideRight
                font {
                    family: Layout.fontSans
                    pixelSize: Layout.s(12)
                    weight: Font.Medium
                    letterSpacing: 0.5
                }
            }

            Text {
                width: parent.width
                text: root.player ? (root.player.trackTitle || "Unknown title") : ""
                color: Theme.on_surface
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.WordWrap
                font {
                    family: Layout.fontSans
                    pixelSize: Layout.s(30)
                    weight: Font.DemiBold
                }
            }

            Text {
                width: parent.width
                text: {
                    if (!root.player)
                        return "";
                    const artist = root.player.trackArtist || "";
                    const album = root.player.trackAlbum || "";
                    return album.length > 0 ? artist + " — " + album : artist;
                }
                color: Theme.on_surface_variant
                elide: Text.ElideRight
                font {
                    family: Layout.fontSans
                    pixelSize: Layout.s(16)
                }
            }

            Item {
                width: parent.width
                height: Layout.s(22)

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: Layout.s(5)
                    radius: height / 2
                    color: Theme.surface_container_highest

                    Rectangle {
                        width: parent.width * (root.player && root.player.length > 0
                            ? Math.max(0, Math.min(1, root.player.position / root.player.length))
                            : 0)
                        height: parent.height
                        radius: height / 2
                        color: Theme.primary

                        Behavior on width {
                            NumberAnimation {
                                duration: 500
                                easing.type: Easing.Linear
                            }
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: Layout.s(16)

                Text {
                    anchors.left: parent.left
                    text: root.player ? root.fmt(root.player.position) : "0:00"
                    color: Theme.on_surface_variant
                    font {
                        family: Layout.fontSans
                        pixelSize: Layout.s(12)
                    }
                }

                Text {
                    anchors.right: parent.right
                    text: root.player ? root.fmt(root.player.length) : "0:00"
                    color: Theme.on_surface_variant
                    font {
                        family: Layout.fontSans
                        pixelSize: Layout.s(12)
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: Layout.s(8)
                spacing: Layout.s(18)

                Repeater {
                    model: [
                        { icon: "skip_previous", action: "previous", size: 30 },
                        { icon: root.player && root.player.isPlaying ? "pause" : "play_arrow", action: "toggle", size: 44 },
                        { icon: "skip_next", action: "next", size: 30 }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        width: modelData.size + Layout.s(16)
                        height: width
                        radius: width / 2
                        color: modelData.action === "toggle" ? Theme.primary : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            color: modelData.action === "toggle" ? Theme.on_primary : Theme.on_surface
                            font {
                                family: Layout.fontIcons
                                pixelSize: modelData.size
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!root.player)
                                    return;
                                if (modelData.action === "toggle")
                                    root.player.togglePlaying();
                                else if (modelData.action === "next")
                                    root.player.next();
                                else if (modelData.action === "previous")
                                    root.player.previous();
                            }
                        }
                    }
                }
            }
        }
    }
}