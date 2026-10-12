import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Item {
    id: root
    visible: false
    width: 0
    height: 0

    readonly property var networkDevices: Networking.devices?.values ?? []

    readonly property var wifiDevice: {
        for (const dev of networkDevices) {
            if (dev.type === NetworkDevice.Wifi)
                return dev;
        }
        return null;
    }

    readonly property var allNetworks: wifiDevice?.networks?.values ?? []

    readonly property var visibleNetworks: {
        const known = allNetworks.filter(n => n.known !== false);
        const sorted = known.slice().sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;
            return (a.name ?? "").localeCompare(b.name ?? "");
        });
        return sorted;
    }

    readonly property var connectedWifiNetwork: {
        for (const dev of networkDevices) {
            const nets = dev.networks?.values ?? [];
            const found = nets.find(n => n.connected);
            if (found)
                return found;
        }
        return null;
    }

    readonly property bool ethernetConnected: networkDevices.some(dev => dev.networks === undefined && dev.connected)

    readonly property bool anyNetworkUp: !!(connectedWifiNetwork || ethernetConnected)

    readonly property string wifiDeviceName: wifiDevice?.name ?? ""

    property string wifiRadio: "enabled"
    readonly property bool wifiEnabled: wifiRadio === "enabled"

    function refreshWifi() {
        wifiRadioQuery.running = false;
        wifiRadioQuery.running = true;
    }

    function setWifi(enabled) {

        if (enabled === undefined)
            enabled = !wifiEnabled;
        wifiRadioToggle.command = ["sh", "-c", "nmcli radio wifi " + (enabled ? "on" : "off") + " && nmcli device wifi rescan"];
        wifiRadioToggle.running = false;
        wifiRadioToggle.running = true;
        wifiRadio = enabled ? "enabled" : "disabled";
        wifiRefreshTimer.running = true;
    }

    readonly property var btAdapter: Bluetooth.defaultAdapter ?? (Bluetooth.adapters?.values?.[0] ?? null)
    readonly property bool btPowered: btAdapter?.enabled ?? false
    readonly property var btDevices: btAdapter?.devices?.values ?? []
    readonly property var btConnectedDevices: btDevices.filter(d => d.connected)

    function deviceName(dev) {
        return dev?.name || dev?.deviceName || dev?.address || "Unknown device";
    }

    function isKnown(dev) {
        return !!(dev && (dev.bonded || dev.paired));
    }

    readonly property var btKnownDevices: {
        const known = btDevices.filter(d => isKnown(d));
        return known.slice().sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;
            return deviceName(a).localeCompare(deviceName(b));
        });
    }

    readonly property var btAvailableDevices: {
        const rest = btDevices.filter(d => !isKnown(d));
        return rest.slice().sort((a, b) => deviceName(a).localeCompare(deviceName(b)));
    }

    property string btBusyAddress: ""

    function setDeviceConnected(dev, wantConnected) {
        if (!dev)
            return;
        btBusyAddress = dev.address ?? "";
        if (wantConnected)
            dev.connect();
        else
            dev.disconnect();
        btBusyTimer.restart();
    }

    function toggleDevice(dev) {
        if (!dev)
            return;
        setDeviceConnected(dev, !dev.connected);
    }

    function pairDevice(dev) {
        if (!dev)
            return;
        btBusyAddress = dev.address ?? "";
        dev.pair();
        btBusyTimer.restart();
    }

    function forgetDevice(dev) {
        if (!dev)
            return;
        btBusyAddress = dev.address ?? "";
        dev.forget();
        btBusyTimer.restart();
    }

    function setDiscovering(on) {
        if (!btAdapter)
            return;
        btAdapter.discovering = on;
    }

    readonly property var activeSink: Pipewire.defaultAudioSink
    readonly property bool isMuted: activeSink?.audio?.muted ?? true
    readonly property real volumeLevel: activeSink?.audio?.volume ?? 0.0

    readonly property var activeSource: Pipewire.defaultAudioSource
    readonly property bool isMutedSource: activeSource?.audio?.muted ?? true
    readonly property real sourceVolumeLevel: activeSource?.audio?.volume ?? 0.0
    readonly property real microphonePercent: Math.round(sourceVolumeLevel * 100)

    function setMicrophone(fraction) {
        if (activeSource) {
            activeSource.audio.volume = fraction;
            activeSource.audio.muted = fraction <= 0.0;
        }
    }

    function toggleMuteSource() {
        if (activeSource)
            activeSource.audio.muted = !activeSource.audio.muted;
    }

    property real brightnessLevel: 0.0

    readonly property real volumePercent: Math.round(volumeLevel * 100)

    readonly property var battery: UPower.displayDevice
    readonly property bool batteryPresent: battery?.isLaptopBattery ?? false
    readonly property real batteryPct: (battery?.percentage ?? 0) * 100
    readonly property bool batteryCharging: battery?.state === UPowerDeviceState.Charging
        || battery?.state === UPowerDeviceState.PendingCharge

    function batteryLabel() {
        if (batteryCharging)
            return Math.round(batteryPct) + "% · Charging";
        return Math.round(batteryPct) + "%";
    }

    function batteryIcon() {
        if (batteryPct >= 95) return "battery_full";
        if (batteryPct >= 75) return "battery_5_bar";
        if (batteryPct >= 55) return "battery_4_bar";
        if (batteryPct >= 35) return "battery_3_bar";
        if (batteryPct >= 15) return "battery_2_bar";
        return "battery_1_bar";
    }

    function refreshBrightness() {

        brightnessQuery.running = false;
        brightnessQuery.running = true;
    }

    function toggleWifi() {
        wifiRadioToggle.running = true;
    }

    function toggleBluetooth() {
        setBluetooth(!btPowered);
    }

    function setBluetooth(enabled) {
        if (enabled === undefined)
            enabled = !btPowered;
        if (!btAdapter)
            return;

        btAdapter.enabled = enabled;
    }

    function toggleMute() {
        if (!activeSink?.audio)
            return;

        activeSink.audio.muted = !activeSink.audio.muted;
        if (!activeSink.audio.muted && activeSink.audio.volume <= 0.001)
            activeSink.audio.volume = 0.4;
    }

    function setVolume(fraction) {
        if (!activeSink?.audio)
            return;
        const clamped = Math.max(0, Math.min(1, fraction));
        activeSink.audio.volume = clamped;

        if (clamped > 0 && activeSink.audio.muted)
            activeSink.audio.muted = false;
    }

    function nudgeVolume(delta) {
        setVolume(volumeLevel + delta);
    }

    function setBrightness(fraction) {
        const pct = Math.round(Math.max(0, Math.min(1, fraction)) * 100);
        brightnessSet.command = ["brightnessctl", "set", pct + "%"];
        brightnessSet.running = true;
    }

    function toggleNetwork(net) {
        if (!net)
            return;
        if (net.connected)
            net.disconnect();
        else
            net.connect();
    }

    Process {
        id: brightnessQuery
        command: ["sh", "-c", "brightnessctl -m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const val = parseInt(this.text.split(",")[3].replace("%", ""));
                if (!isNaN(val))
                    root.brightnessLevel = val / 100.0;
            }
        }
    }

    Process {
        id: brightnessSet
        command: ["brightnessctl", "set", "50%"]
        stdout: StdioCollector {
            onStreamFinished: root.refreshBrightness()
        }
    }

    Process {
        id: wifiRadioToggle
    }

    Process {
        id: wifiRadioQuery
        command: ["sh", "-c", "nmcli -t -f WIFI radio wifi | head -1"]

        stdout: StdioCollector {
            onStreamFinished: {
                const state = this.text.trim();
                if (state === "enabled" || state === "disabled" || state === "missing")
                    root.wifiRadio = state;
            }
        }
    }

    Timer {
        id: btBusyTimer
        interval: 2500
        onTriggered: root.btBusyAddress = ""
    }

    Timer {
        id: wifiRefreshTimer
        interval: 4000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshWifi()
    }

    Component.onCompleted: {
        refreshBrightness();
        refreshWifi();
    }
}
