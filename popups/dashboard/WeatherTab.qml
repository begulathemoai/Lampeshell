import QtQuick
import qs.theme
import qs.services

// Forecast view backed by the Weather service.
Item {
    id: root

    implicitWidth: Layout.s(828)
    implicitHeight: Layout.s(470)

    Component.onCompleted: Weather.reload()

    readonly property var today: Weather.forecast && Weather.forecast.length > 0 ? Weather.forecast[0] : null

    Column {
        anchors.fill: parent
        anchors.margins: Layout.s(16)
        spacing: Layout.s(14)

        // Header: city + date + sunrise/sunset.
        Row {
            width: parent.width

            Column {
                id: cityColumn
                spacing: Layout.s(2)

                Text {
                    text: Weather.city.length > 0 ? Weather.city : (Weather.loading ? "Loading…" : "Unknown location")
                    color: Theme.on_surface
                    font {
                        family: Layout.fontSans
                        pixelSize: Layout.s(24)
                        weight: Font.DemiBold
                    }
                }

                Text {
                    text: new Date().toLocaleDateString(Qt.locale(), "dddd, MMMM d")
                    color: Theme.on_surface_variant
                    font {
                        family: Layout.fontSans
                        pixelSize: Layout.s(13)
                    }
                }
            }

            Item {
                width: parent.width - cityColumn.width - stats.width
                height: 1
            }

            Row {
                id: stats
                spacing: Layout.s(18)

                Row {
                    spacing: Layout.s(8)

                    Text {
                        text: "wb_twilight"
                        color: Theme.tertiary
                        font {
                            family: Layout.fontIcons
                            pixelSize: Layout.s(22)
                        }
                    }

                    Column {
                        Text {
                            text: "Sunrise"
                            color: Theme.on_surface_variant
                            font {
                                family: Layout.fontSans
                                pixelSize: Layout.s(11)
                            }
                        }
                        Text {
                            text: Weather.sunrise
                            color: Theme.on_surface
                            font {
                                family: Layout.fontSans
                                pixelSize: Layout.s(13)
                                weight: Font.Medium
                            }
                        }
                    }
                }

                Row {
                    spacing: Layout.s(8)

                    Text {
                        text: "bedtime"
                        color: Theme.tertiary
                        font {
                            family: Layout.fontIcons
                            pixelSize: Layout.s(22)
                        }
                    }

                    Column {
                        Text {
                            text: "Sunset"
                            color: Theme.on_surface_variant
                            font {
                                family: Layout.fontSans
                                pixelSize: Layout.s(11)
                            }
                        }
                        Text {
                            text: Weather.sunset
                            color: Theme.on_surface
                            font {
                                family: Layout.fontSans
                                pixelSize: Layout.s(13)
                                weight: Font.Medium
                            }
                        }
                    }
                }
            }
        }

        // Big current conditions.
        Rectangle {
            width: parent.width
            height: Layout.s(150)
            radius: Layout.s(28)
            color: Theme.surface_container

            Row {
                anchors.centerIn: parent
                spacing: Layout.s(28)

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Weather.icon
                    color: Theme.secondary
                    font {
                        family: Layout.fontIcons
                        pixelSize: Layout.s(88)
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Layout.s(2)

                    Text {
                        text: Weather.temp
                        color: Theme.primary
                        font {
                            family: Layout.fontSans
                            pixelSize: Layout.s(56)
                            weight: Font.Medium
                        }
                    }

                    Text {
                        text: Weather.description
                        color: Theme.on_surface_variant
                        font {
                            family: Layout.fontSans
                            pixelSize: Layout.s(15)
                        }
                    }
                }
            }
        }

        // Detail cards.
        Row {
            width: parent.width
            spacing: Layout.s(14)

            Repeater {
                model: [
                    { icon: "water_drop", label: "Humidity", value: Weather.humidity + "%", color: Theme.secondary },
                    { icon: "thermostat", label: "Feels like", value: Weather.feelsLike, color: Theme.primary },
                    { icon: "air", label: "Wind", value: Weather.windSpeedText, color: Theme.tertiary }
                ]

                Rectangle {
                    required property var modelData

                    width: (parent.width - Layout.s(28)) / 3
                    height: Layout.s(64)
                    radius: Layout.s(16)
                    color: Theme.surface_container

                    Row {
                        anchors.centerIn: parent
                        spacing: Layout.s(12)

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.icon
                            color: modelData.color
                            font {
                                family: Layout.fontIcons
                                pixelSize: Layout.s(26)
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0

                            Text {
                                text: modelData.label
                                color: Theme.on_surface_variant
                                font {
                                    family: Layout.fontSans
                                    pixelSize: Layout.s(11)
                                }
                            }

                            Text {
                                text: modelData.value
                                color: Theme.on_surface
                                font {
                                    family: Layout.fontSans
                                    pixelSize: Layout.s(15)
                                    weight: Font.DemiBold
                                }
                            }
                        }
                    }
                }
            }
        }

        // 7-day forecast.
        Text {
            visible: forecastRow.count > 0
            text: "7-day forecast"
            color: Theme.on_surface
            font {
                family: Layout.fontSans
                pixelSize: Layout.s(14)
                weight: Font.DemiBold
            }
        }

        Row {
            id: forecastRow

            width: parent.width
            spacing: Layout.s(12)

            Repeater {
                model: Weather.forecast

                Rectangle {
                    required property int index
                    required property var modelData

                    width: (forecastRow.width - Layout.s(72)) / 7
                    height: Layout.s(120)
                    radius: Layout.s(18)
                    color: Theme.surface_container

                    Column {
                        anchors.centerIn: parent
                        spacing: Layout.s(6)

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: index === 0 ? "Today" : new Date(modelData.date).toLocaleDateString(Qt.locale(), "ddd")
                            color: Theme.primary
                            font {
                                family: Layout.fontSans
                                pixelSize: Layout.s(13)
                                weight: Font.DemiBold
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: new Date(modelData.date).toLocaleDateString(Qt.locale(), "MMM d")
                            color: Theme.on_surface_variant
                            opacity: 0.7
                            font {
                                family: Layout.fontSans
                                pixelSize: Layout.s(11)
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Weather.iconForCode(modelData.weatherCode, 1)
                            color: Theme.secondary
                            font {
                                family: Layout.fontIcons
                                pixelSize: Layout.s(30)
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Weather.formatForecastTemp(modelData.minTempC) + " / " + Weather.formatForecastTemp(modelData.maxTempC)
                            color: Theme.tertiary
                            font {
                                family: Layout.fontSans
                                pixelSize: Layout.s(11)
                                weight: Font.DemiBold
                            }
                        }
                    }
                }
            }
        }

        Item {
            width: 1
            height: 1
        }
    }
}
