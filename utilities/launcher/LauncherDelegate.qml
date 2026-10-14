import QtQuick
import Quickshell.Widgets
import "../../theme"
import qs.services

Item {
    id: delegateRoot

    width: ListView.view ? ListView.view.width : 0
    height: 57

    readonly property bool isCalc: !!modelData.__calc
    readonly property bool isAction: !!modelData.__action
    readonly property bool isFavourite: !delegateRoot.isCalc && !delegateRoot.isAction && delegateRoot.matchesFavourite(modelData)

    readonly property string descriptionText: (delegateRoot.isAction || delegateRoot.isCalc)
        ? (modelData.genericName || "")
        : (modelData.comment || modelData.genericName || modelData.name || "")

    readonly property bool containsMouse: itemMouseArea.containsMouse

    function matchesFavourite(entry) {
        if (!entry || !entry.id)
            return false;
        const patterns = SettingsStore.values.favouriteApps || [];
        for (let i = 0; i < patterns.length; i++) {
            try {
                if (new RegExp(patterns[i]).test(entry.id))
                    return true;
            } catch (e) {
                if (entry.id === patterns[i])
                    return true;
            }
        }
        return false;
    }

    function launch() {
        if (delegateRoot.isCalc) {
            ctrl.copyCalcResult(modelData);
            return;
        }
        if (delegateRoot.isAction) {
            ctrl.runAction(modelData.__action);
            return;
        }
        ctrl.launchApp(modelData);
    }

    Rectangle {
        id: hoverBg

        anchors.fill: parent
        radius: 16
        color: Theme.on_surface
        opacity: delegateRoot.containsMouse ? 0.08 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.duration(Motion.defaultEffects)
                easing.type: Easing.OutCubic
            }
        }
    }

    Item {
        id: rowContent

        anchors.fill: parent
        anchors.margins: 8

        IconImage {
            id: appIcon

            visible: !delegateRoot.isAction && !delegateRoot.isCalc
            width: rowContent.height * 0.8
            height: rowContent.height * 0.8
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            source: {
                if (!modelData.icon || modelData.icon === "")
                    return "image://icon/application-x-executable";
                if (modelData.icon.startsWith("/"))
                    return "file://" + modelData.icon;
                return "image://icon/" + modelData.icon;
            }

            onStatusChanged: {
                if (status === Image.Error)
                    source = "image://icon/application-x-executable";
            }
        }

        Text {
            id: actionIcon

            visible: delegateRoot.isAction || delegateRoot.isCalc
            width: rowContent.height * 0.8
            height: rowContent.height * 0.8
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            text: modelData.icon || "chevron_right"
            color: Theme.on_surface_variant

            font {
                family: "Material Symbols Rounded"
                pointSize: 24
            }
        }

        Item {
            id: textItem

            anchors.left: appIcon.visible ? appIcon.right : actionIcon.right
            anchors.leftMargin: 12
            anchors.verticalCenter: appIcon.verticalCenter

            width: parent.width - appIcon.width - favouriteIcon.width
            height: name.implicitHeight + comment.implicitHeight

            Text {
                id: name

                width: parent.width
                text: modelData.name
                color: Theme.on_surface
                elide: Text.ElideRight

                font {
                    family: "Google Sans"
                    pointSize: 14
                    weight: Font.Normal
                }
            }

            Text {
                id: comment

                width: delegateRoot.width - appIcon.width - favouriteIcon.width - 32
                text: delegateRoot.descriptionText
                visible: text.length > 0
                color: Theme.outline
                elide: Text.ElideRight
                anchors.top: name.bottom

                font {
                    family: "Google Sans"
                    pointSize: 12
                    weight: Font.Normal
                }
            }
        }

        Loader {
            id: favouriteIcon

            active: delegateRoot.isFavourite
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            sourceComponent: Text {
                text: "favorite"
                color: Theme.primary

                font {
                    family: "Material Symbols Rounded"
                    pointSize: 15
                    weight: Font.Normal
                    variableAxes: ({ "FILL": 1.0 })
                }
            }
        }
    }

    MouseArea {
        id: itemMouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: delegateRoot.launch()
    }
}
