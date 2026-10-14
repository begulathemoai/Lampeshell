pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string location: SettingsStore.get("weatherLocation") || ""
    readonly property string units: SettingsStore.get("weatherUnits") || "metric"

    property string city: ""
    property real latitude: NaN
    property real longitude: NaN

    property var cc: null
    property var forecast: []
    property var hourlyForecast: []

    property bool loading: false
    property bool failed: false

    readonly property bool imperial: units === "imperial"

    readonly property string icon: {
        if (!cc)
            return "cloud_alert";
        return iconForCode(cc.weatherCode, cc.isDay);
    }
    readonly property string description: cc ? descriptionForCode(cc.weatherCode) : qsTr("No weather")
    readonly property string temp: cc ? formatTemp(cc.tempC) : "--"
    readonly property string feelsLike: cc ? formatTemp(cc.feelsLikeC) : "--"
    readonly property int humidity: cc ? cc.humidity : 0
    readonly property real windSpeed: cc ? cc.windSpeed : 0
    readonly property string windSpeedText: cc ? formatWind(cc.windSpeed) : "--"
    readonly property string sunrise: cc ? formatTime(cc.sunrise) : "--:--"
    readonly property string sunset: cc ? formatTime(cc.sunset) : "--:--"

    readonly property string unitSymbol: imperial ? "°F" : "°C"

    function formatTemp(celsius) {
        if (celsius === undefined || celsius === null || isNaN(celsius))
            return "--";
        const value = imperial ? celsius * 9 / 5 + 32 : celsius;
        return Math.round(value) + unitSymbol;
    }

    function formatForecastTemp(celsius) {
        if (celsius === undefined || celsius === null || isNaN(celsius))
            return "--";
        const value = imperial ? celsius * 9 / 5 + 32 : celsius;
        return Math.round(value) + "°";
    }

    function formatWind(kmh) {
        if (kmh === undefined || kmh === null || isNaN(kmh))
            return "--";
        return imperial ? Math.round(kmh / 1.609) + " mph" : Math.round(kmh) + " km/h";
    }

    function formatTime(iso) {
        if (!iso)
            return "--:--";
        const d = new Date(String(iso).replace(" ", "T"));
        if (isNaN(d.getTime()))
            return "--:--";
        return Qt.formatDateTime(d, "h:mm AP");
    }

    function iconForCode(code, isDay) {
        const map = {
            0: ["clear_day", "clear_night"],
            1: ["clear_day", "clear_night"],
            2: ["partly_cloudy_day", "partly_cloudy_night"],
            3: ["cloud", "cloud"],
            45: ["foggy", "foggy"],
            48: ["foggy", "foggy"],
            51: ["rainy", "rainy"],
            53: ["rainy", "rainy"],
            55: ["rainy", "rainy"],
            56: ["rainy", "rainy"],
            57: ["rainy", "rainy"],
            61: ["rainy", "rainy"],
            63: ["rainy", "rainy"],
            65: ["rainy", "rainy"],
            66: ["rainy", "rainy"],
            67: ["rainy", "rainy"],
            71: ["cloudy_snowing", "cloudy_snowing"],
            73: ["cloudy_snowing", "cloudy_snowing"],
            75: ["snowing_heavy", "snowing_heavy"],
            77: ["cloudy_snowing", "cloudy_snowing"],
            80: ["rainy", "rainy"],
            81: ["rainy", "rainy"],
            82: ["rainy", "rainy"],
            85: ["cloudy_snowing", "cloudy_snowing"],
            86: ["snowing_heavy", "snowing_heavy"],
            95: ["thunderstorm", "thunderstorm"],
            96: ["thunderstorm", "thunderstorm"],
            99: ["thunderstorm", "thunderstorm"]
        };
        const pair = map[code];
        if (!pair)
            return "cloud";
        return isDay === 0 ? pair[1] : pair[0];
    }

    function descriptionForCode(code) {
        const map = {
            0: qsTr("Clear"),
            1: qsTr("Clear"),
            2: qsTr("Partly cloudy"),
            3: qsTr("Overcast"),
            45: qsTr("Fog"),
            48: qsTr("Fog"),
            51: qsTr("Drizzle"),
            53: qsTr("Drizzle"),
            55: qsTr("Drizzle"),
            56: qsTr("Freezing drizzle"),
            57: qsTr("Freezing drizzle"),
            61: qsTr("Light rain"),
            63: qsTr("Rain"),
            65: qsTr("Heavy rain"),
            66: qsTr("Light rain"),
            67: qsTr("Heavy rain"),
            71: qsTr("Light snow"),
            73: qsTr("Snow"),
            75: qsTr("Heavy snow"),
            77: qsTr("Snow"),
            80: qsTr("Light rain"),
            81: qsTr("Rain"),
            82: qsTr("Heavy rain"),
            85: qsTr("Light snow showers"),
            86: qsTr("Heavy snow showers"),
            95: qsTr("Thunderstorm"),
            96: qsTr("Thunderstorm with hail"),
            99: qsTr("Thunderstorm with hail")
        };
        return map[code] || qsTr("Unknown");
    }

    function hasCoords() {
        return !isNaN(root.latitude) && !isNaN(root.longitude);
    }

    function setCoords(lat, lon) {
        root.latitude = Number(lat);
        root.longitude = Number(lon);
    }

    function reload() {
        root.failed = false;
        const loc = root.location.trim();

        if (loc.length === 0) {
            lookupByIp();
            return;
        }

        const parts = loc.split(",");
        const lat = parseFloat(parts[0]);
        const lon = parseFloat(parts[1]);
        if (parts.length >= 2 && isFinite(lat) && isFinite(lon)) {
            setCoords(lat, lon);
            reverseGeocode();
            fetchWeather();
        } else {
            geocodeCity(loc);
        }
    }

    function lookupByIp() {
        root.loading = true;
        ipApiProc.command = ["curl", "-s", "-m", "10", "http://ip-api.com/json?fields=status,message,city,lat,lon"];
        ipApiProc.running = true;
    }

    function geocodeCity(name) {
        root.loading = true;
        const lang = (Qt.locale().name.split("_")[0] || "en");
        geocodeProc.command = ["curl", "-s", "-m", "10", "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(name) + "&count=1&language=" + lang + "&format=json"];
        geocodeProc.running = true;
    }

    function reverseGeocode() {
        if (!hasCoords())
            return;
        const lang = (Qt.locale().name.split("_")[0] || "en");
        reverseProc.command = ["curl", "-s", "-m", "10", "-A", "lampshell", "https://nominatim.openstreetmap.org/reverse?lat=" + root.latitude + "&lon=" + root.longitude + "&format=geocodejson&accept-language=" + lang];
        reverseProc.running = true;
    }

    function fetchWeather() {
        if (!hasCoords())
            return;
        root.loading = true;
        const params = [
            "latitude=" + root.latitude,
            "longitude=" + root.longitude,
            "hourly=weather_code,temperature_2m,precipitation_probability",
            "daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset",
            "current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m",
            "timezone=auto",
            "forecast_days=7"
        ];
        weatherProc.command = ["curl", "-s", "-m", "15", "https://api.open-meteo.com/v1/forecast?" + params.join("&")];
        weatherProc.running = true;
    }

    function applyWeather(text) {
        let json;
        try {
            json = JSON.parse(text);
        } catch (e) {
            root.loading = false;
            root.failed = true;
            return;
        }

        if (!json || !json.current || !json.daily) {
            root.loading = false;
            root.failed = true;
            return;
        }

        root.cc = {
            weatherCode: json.current.weather_code,
            tempC: json.current.temperature_2m,
            feelsLikeC: json.current.apparent_temperature,
            humidity: json.current.relative_humidity_2m,
            windSpeed: json.current.wind_speed_10m,
            isDay: json.current.is_day,
            sunrise: json.daily.sunrise ? json.daily.sunrise[0] : "",
            sunset: json.daily.sunset ? json.daily.sunset[0] : ""
        };

        const days = [];
        if (json.daily.time) {
            for (let i = 0; i < json.daily.time.length; i++) {
                days.push({
                    date: json.daily.time[i].replace(/-/g, "/"),
                    maxTempC: json.daily.temperature_2m_max[i],
                    minTempC: json.daily.temperature_2m_min[i],
                    weatherCode: json.daily.weather_code[i]
                });
            }
        }
        root.forecast = days;

        const hours = [];
        const now = new Date();
        if (json.hourly && json.hourly.time) {
            for (let i = 0; i < json.hourly.time.length; i++) {
                const time = new Date(json.hourly.time[i].replace("T", " "));
                if (time < now)
                    continue;
                hours.push({
                    time: json.hourly.time[i],
                    hour: time.getHours(),
                    tempC: Math.round(json.hourly.temperature_2m[i]),
                    precipChance: json.hourly.precipitation_probability[i],
                    weatherCode: json.hourly.weather_code[i],
                    isDay: 1
                });
                if (hours.length >= 24)
                    break;
            }
        }
        root.hourlyForecast = hours;

        root.loading = false;
        root.failed = false;
    }

    onLocationChanged: reload()
    Component.onCompleted: reload()

    Timer {
        interval: 3600000
        running: true
        repeat: true
        onTriggered: root.fetchWeather()
    }

    Process {
        id: ipApiProc
        stdout: StdioCollector {
            onStreamFinished: {
                let response;
                try {
                    response = JSON.parse(text);
                } catch (e) {
                    root.loading = false;
                    root.failed = true;
                    return;
                }
                const lat = Number(response.lat);
                const lon = Number(response.lon);
                if (response.status !== "success" || !isFinite(lat) || !isFinite(lon)) {
                    root.loading = false;
                    root.failed = true;
                    return;
                }
                root.city = response.city || "";
                root.setCoords(lat, lon);
                root.fetchWeather();
            }
        }
    }

    Process {
        id: geocodeProc
        stdout: StdioCollector {
            onStreamFinished: {
                let json;
                try {
                    json = JSON.parse(text);
                } catch (e) {
                    root.loading = false;
                    root.failed = true;
                    return;
                }
                if (!json.results || json.results.length === 0) {
                    root.loading = false;
                    root.failed = true;
                    return;
                }
                const result = json.results[0];
                root.city = result.name || "";
                root.setCoords(result.latitude, result.longitude);
                root.fetchWeather();
            }
        }
    }

    Process {
        id: reverseProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const geo = JSON.parse(text).features?.[0]?.properties?.geocoding;
                    if (!geo)
                        return;
                    const name = geo.type === "city" ? geo.name : geo.city;
                    if (name)
                        root.city = name;
                } catch (e) {
                    // City name is cosmetic; keep whatever we have.
                }
            }
        }
    }

    Process {
        id: weatherProc
        stdout: StdioCollector {
            onStreamFinished: root.applyWeather(text)
        }
    }
}
