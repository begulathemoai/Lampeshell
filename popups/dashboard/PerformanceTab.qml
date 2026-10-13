import QtQuick
import qs.theme
import qs.services

// System monitor built on the SystemStats service.
Item {
    id: root

    implicitWidth: Layout.s(828)
    implicitHeight: Layout.s(470)

    Grid {
        id: grid
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Layout.s(8)
        height: root.height - Layout.s(56)
        columns: 2
        rowSpacing: Layout.s(16)
        columnSpacing: Layout.s(16)

        readonly property real cardW: (grid.width - grid.columnSpacing) / 2
        readonly property real cardH: (grid.height - grid.rowSpacing) / 2

        // CPU hero card.
        Rectangle {
            width: grid.cardW
            height: grid.cardH
            radius: Layout.s(24)
            color: Theme.surface_container

            Row {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: Layout.s(20)
                spacing: Layout.s(16)

                ProgressRing {
                    width: Layout.s(76)
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    value: SystemStats.cpu / 100
                    fgColor: Theme.primary
                    strokeWidth: Layout.s(7)

                    Text {
                        anchors.centerIn: parent
                        text: "memory"
                        color: Theme.primary
                        font {
                            family: Layout.fontIcons
                            pixelSize: Layout.s(24)
                        }
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Layout.s(2)

                    Text {
                        text: "CPU"
                        color: Theme.primary
                        font {
                            family: Layout.fontSans
                            pixelSize: Layout.s(16)
                            weight: Font.DemiBold
                        }
                    }

                    Text {
                        width: Layout.s(150)
                        text: SystemStats.cpuName
                        color: Theme.on_surface_variant
                        elide: Text.ElideRight
                        font {
                            family: Layout.fontSans
                            pixelSize: Layout.s(12)
                        }
                    }
                }
            }

            Column {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: Layout.s(20)
                spacing: Layout.s(6)

                Row {
                    spacing: Layout.s(6)

                    Text {
                        text: SystemStats.hasCpuTemp && SystemStats.cpuTemp > 90 ? "thermometer_alert" : "thermometer"
                        color: SystemStats.hasCpuTemp && SystemStats.cpuTemp > 90 ? Theme.critical : Theme.primary
                        font {
                            family: Layout.fontIcons
                            pixelSize: Layout.s(18)
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: SystemStats.hasCpuTemp ? SystemStats.cpuTemp + "°C" : "--"
                        color: Theme.on_surface
                        font {
                            family: Layout.fontSans
                            pixelSize: Layout.s(14)
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "• load " + SystemStats.load1.toFixed(2)
                        color: Theme.on_surface_variant
                        font {
                            family: Layout.fontSans
                            pixelSize: Layout.s(12)
                        }
                    }
                }
            }
        }

        // GPU hero card.
        Rectangle {
            width: grid.cardW
            height: grid.cardH
            radius: Layout.s(24)
            color: Theme.surface_container
            visible: SystemStats.hasGpu

            Row {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: Layout.s(20)
                spacing: Layout.s(16)

                ProgressRing {
                    width: Layout.s(76)
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    value: SystemStats.gpuUsage / 100
                    fgColor: Theme.secondary
                    strokeWidth: Layout.s(7)

                    Text {
                        anchors.centerIn: parent
                        text: "desktop_windows"
                        color: Theme.secondary
                        font {
                            family: Layout.fontIcons
                            pixelSize: Layout.s(24)
                        }
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Layout.s(2)

                    Text {
                        text: "GPU"
                        color: Theme.secondary
                        font {
                            family: Layout.fontSans
                            pixelSize: Layout.s(16)
                            weight: Font.DemiBold
                        }
                    }

                    Text {
                        width: Layout.s(150)
                        text: SystemStats.gpuName
                        color: Theme.on_surface_variant
                        elide: Text.ElideRight
                        font {
                            family: Layout.fontSans
                            pixelSize: Layout.s(12)
                        }
                    }
                }
            }

            Row {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: Layout.s(20)
                spacing: Layout.s(8)

                Text {
                    text: "thermometer"
                    color: Theme.secondary
                    font {
                        family: Layout.fontIcons
                        pixelSize: Layout.s(18)
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: SystemStats.hasGpuTemp ? SystemStats.gpuTemp + "°C" : "--"
                    color: Theme.on_surface
                    font {
                        family: Layout.fontSans
                        pixelSize: Layout.s(14)
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: SystemStats.gpuMemTotal > 0
                        ? SystemStats.formatBytes(SystemStats.gpuMemUsed * 1024 * 1024, 0) + " / " + SystemStats.formatBytes(SystemStats.gpuMemTotal * 1024 * 1024, 0)
                        : ""
                    color: Theme.on_surface_variant
                    font {
                        family: Layout.fontSans
                        pixelSize: Layout.s(12)
                    }
                }
            }
        }

        // Memory card.
        Rectangle {
            width: grid.cardW
            height: grid.cardH
            radius: Layout.s(24)
            color: Theme.surface_container

            Column {
                anchors.centerIn: parent
                spacing: Layout.s(8)

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Layout.s(8)

                    Text {
                        text: "memory_alt"
                        color: Theme.tertiary
                        font {
                            family: Layout.fontIcons
                            pixelSize: Layout.s(20)
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Memory"
                        color: Theme.on_surface
                        font {
                            family: Layout.fontSans
                            pixelSize: Layout.s(16)
                            weight: Font.DemiBold
                        }
                    }
                }

                ProgressRing {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Layout.s(120)
                    height: width
                    value: SystemStats.memFraction
                    fgColor: Theme.tertiary
                    startAngle: -225
                    sweepAngle: 270
                    strokeWidth: Layout.s(9)

                    Column {
                        anchors.centerIn: parent
                        spacing: 0

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Math.round(SystemStats.memFraction * 100) + "%"
                            color: Theme.tertiary
                            font {
                                family: Layout.fontSans
                                pixelSize: Layout.s(22)
                                weight: Font.DemiBold
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Used"
                            color: Theme.on_surface_variant
                            font {
                                family: Layout.fontSans
                                pixelSize: Layout.s(11)
                            }
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: SystemStats.formatBytes(SystemStats.memUsed) + " / " + SystemStats.formatBytes(SystemStats.memTotal)
                    color: Theme.on_surface
                    font {
                        family: Layout.fontSans
                        pixelSize: Layout.s(13)
                    }
                }
            }
        }

        // Storage card.
        Rectangle {
            width: grid.cardW
            height: grid.cardH
            radius: Layout.s(24)
            color: Theme.surface_container

            Column {
                anchors.centerIn: parent
                spacing: Layout.s(8)

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Layout.s(8)

                    Text {
                        text: "hard_drive"
                        color: Theme.secondary
                        font {
                            family: Layout.fontIcons
                            pixelSize: Layout.s(20)
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Storage"
                        color: Theme.on_surface
                        font {
                            family: Layout.fontSans
                            pixelSize: Layout.s(16)
                            weight: Font.DemiBold
                        }
                    }
                }

                ProgressRing {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Layout.s(120)
                    height: width
                    value: SystemStats.diskFraction
                    fgColor: Theme.secondary
                    startAngle: -225
                    sweepAngle: 270
                    strokeWidth: Layout.s(9)

                    Column {
                        anchors.centerIn: parent
                        spacing: 0

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Math.round(SystemStats.diskFraction * 100) + "%"
                            color: Theme.secondary
                            font {
                                family: Layout.fontSans
                                pixelSize: Layout.s(22)
                                weight: Font.DemiBold
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Used"
                            color: Theme.on_surface_variant
                            font {
                                family: Layout.fontSans
                                pixelSize: Layout.s(11)
                            }
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: SystemStats.formatBytes(SystemStats.diskUsed) + " / " + SystemStats.formatBytes(SystemStats.diskTotal)
                    color: Theme.on_surface
                    font {
                        family: Layout.fontSans
                        pixelSize: Layout.s(13)
                    }
                }
            }
        }
    }

    // Network + uptime footer.
    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Layout.s(24)
        spacing: Layout.s(24)

        Row {
            spacing: Layout.s(6)

            Text {
                text: "download"
                color: Theme.tertiary
                font {
                    family: Layout.fontIcons
                    pixelSize: Layout.s(18)
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: SystemStats.formatBytes(SystemStats.netRx) + "/s"
                color: Theme.on_surface
                font {
                    family: Layout.fontSans
                    pixelSize: Layout.s(13)
                }
            }
        }

        Row {
            spacing: Layout.s(6)

            Text {
                text: "upload"
                color: Theme.secondary
                font {
                    family: Layout.fontIcons
                    pixelSize: Layout.s(18)
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: SystemStats.formatBytes(SystemStats.netTx) + "/s"
                color: Theme.on_surface
                font {
                    family: Layout.fontSans
                    pixelSize: Layout.s(13)
                }
            }
        }

        Row {
            spacing: Layout.s(6)

            Text {
                text: "schedule"
                color: Theme.on_surface_variant
                font {
                    family: Layout.fontIcons
                    pixelSize: Layout.s(18)
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Up " + SystemStats.formatDuration(SystemStats.uptime)
                color: Theme.on_surface
                font {
                    family: Layout.fontSans
                    pixelSize: Layout.s(13)
                }
            }
        }
    }
}
