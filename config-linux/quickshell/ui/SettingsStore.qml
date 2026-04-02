import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: store

    // Everforest (dark medium)
    property color bgDim: "#232A2E"
    property color bg0: "#2D353B"
    property color bg1: "#343F44"
    property color bg2: "#3D484D"
    property color bg3: "#475258"
    property color fg: "#D3C6AA"
    property color grey1: "#859289"
    property color green: "#A7C080"
    property color aqua: "#83C092"
    property color yellow: "#DBBC7F"

    property int panelWidth: 760
    property int windowGap: 10
    property int windowBorder: 2
    property int windowRadius: 0

    property string settingsStatus: ""

    property string networkState: "unavailable"
    property string networkSsid: ""
    property int networkSignal: 0
    property bool wifiEnabled: false
    property string wifiInterface: ""

    property bool bluetoothEnabled: false
    property int bluetoothConnections: 0

    property bool audioMuted: false
    property int audioVolume: 0
    property bool micMuted: false
    property int micVolume: 0
    property string defaultSink: ""

    property int batteryPercent: 0
    property string batteryStatus: "Unknown"

    property bool wifiScanning: false
    property int scanTick: 0
    property string wifiListStatus: "Press Scan to discover Wi-Fi networks"

    property bool bluetoothScanning: false
    property int bluetoothScanTick: 0
    property string bluetoothListStatus: "Press Scan to discover Bluetooth devices"

    property int scanCooldownMs: 30000
    property double lastWifiScanAt: 0
    property double lastBluetoothScanAt: 0

    property string themesStatus: ""
    property string selectedTheme: ""
    property string selectedBackgroundPath: ""
    property string currentThemeName: ""
    property string currentBackgroundPath: ""

    property string activeScreenName: ""
    property bool initialScreenResolved: false

    // settingsctl job state
    property string pendingSettingsJob: ""
    property bool pendingSettingsForce: false
    property string pendingSettingsArg: ""
    property var settingsQueue: []

    property alias wifiModel: wifiNetworksModel
    property alias btModel: bluetoothDevicesModel
    property alias sinksModel: audioSinksModel
    property alias themesListModel: themesModel
    property alias backgroundsModel: themeBackgroundsModel

    ListModel {
        id: wifiNetworksModel
    }

    ListModel {
        id: bluetoothDevicesModel
    }

    ListModel {
        id: audioSinksModel
    }

    ListModel {
        id: themesModel
    }

    ListModel {
        id: themeBackgroundsModel
    }

    function run(proc) {
        if (!proc.running)
            proc.running = true;
    }

    function clearModel(model) {
        while (model.count > 0)
            model.remove(0);
    }

    function shQuote(value) {
        return "'" + String(value).replace(/'/g, "'\"'\"'") + "'";
    }

    function safeJsonParse(text) {
        try {
            return JSON.parse(String(text));
        } catch (e) {
            return null;
        }
    }

    function setStatus(message) {
        settingsStatus = message;
        settingsStatusClear.restart();
        console.log("settingsStatus=" + message);
    }

    function runSettingsRequest(job, force, arg) {
        pendingSettingsJob = job;
        pendingSettingsForce = force;
        pendingSettingsArg = arg;
        var commandText = "settingsctl " + job;
        if (arg !== "")
            commandText += " " + shQuote(arg);
        settingsctlProc.command = ["bash", "-lc", commandText];
        run(settingsctlProc);
    }

    function settingsctl(job, force, arg) {
        var request = {
            job: job,
            force: !!force,
            arg: arg === undefined ? "" : String(arg)
        };

        if (settingsctlProc.running || pendingSettingsJob !== "") {
            settingsQueue.push(request);
            return true;
        }

        runSettingsRequest(request.job, request.force, request.arg);
        return true;
    }

    function refreshCoreStatus() {
        settingsctl("wifi status");
        settingsctl("bt status");
        settingsctl("audio status");
        settingsctl("audio list-sinks");
        settingsctl("theme current");
        settingsctl("wallpaper status");
        settingsctl("system battery");
        settingsctl("system active-monitor");
    }

    function refreshWifiList(force) {
        if (wifiScanning)
            return;

        var now = Date.now();
        var waitMs = scanCooldownMs - (now - lastWifiScanAt);
        if (!force && waitMs > 0)
            return;
        if (force && waitMs > 0) {
            wifiListStatus = "Please wait " + Math.ceil(waitMs / 1000) + "s before scanning again";
            return;
        }

        settingsctl("wifi list", force);
        wifiScanning = true;
        wifiListStatus = "Scanning Wi-Fi...";
        lastWifiScanAt = now;
    }

    function startWifiScan() {
        refreshWifiList(true);
    }

    function toggleWifi() {
        settingsctl("wifi toggle", true, wifiEnabled ? "off" : "on");
    }

    function connectWifi(target) {
        settingsctl("wifi connect", true, target);
    }

    function refreshBluetoothList(force) {
        if (bluetoothScanning)
            return;

        var now = Date.now();
        var waitMs = scanCooldownMs - (now - lastBluetoothScanAt);
        if (!force && waitMs > 0)
            return;
        if (force && waitMs > 0) {
            bluetoothListStatus = "Please wait " + Math.ceil(waitMs / 1000) + "s before scanning again";
            return;
        }

        settingsctl("bt list", force);
        bluetoothScanning = true;
        bluetoothListStatus = "Scanning Bluetooth...";
        lastBluetoothScanAt = now;
    }

    function startBluetoothScan() {
        refreshBluetoothList(true);
    }

    function toggleBluetooth() {
        settingsctl("bt toggle", true, bluetoothEnabled ? "off" : "on");
    }

    function connectBluetooth(address, connected) {
        settingsctl(connected ? "bt disconnect" : "bt connect", true, address);
    }

    function setAudioVolume(value) {
        audioVolume = Math.max(0, Math.min(100, Math.round(value)));
        settingsctl("audio set-volume", true, String(audioVolume));
    }

    function setMicVolume(value) {
        micVolume = Math.max(0, Math.min(100, Math.round(value)));
        settingsctl("audio set-mic-volume", true, String(micVolume));
    }

    function toggleAudioMute() {
        settingsctl("audio toggle-mute", true);
    }

    function toggleMicMute() {
        settingsctl("audio toggle-mic", true);
    }

    function doSetDefaultSink(name) {
        settingsctl("audio set-default-sink", true, name);
    }

    function refreshThemesData() {
        settingsctl("theme list");
    }

    function requestThemeBackgrounds(themeName) {
        selectedTheme = themeName;
        if (themeName === "") {
            clearModel(themeBackgroundsModel);
            selectedBackgroundPath = "";
            themesStatus = "Select a theme to preview backgrounds";
            return;
        }
        settingsctl("theme backgrounds", false, themeName);
    }

    function applySelectedTheme() {
        if (selectedTheme === "") {
            themesStatus = "Select a theme first";
            return;
        }
        settingsctl("theme set", true, selectedTheme);
    }

    function setSelectedBackground() {
        if (selectedBackgroundPath === "") {
            themesStatus = "Select a background first";
            return;
        }
        settingsctl("wallpaper set", true, selectedBackgroundPath);
    }

    function shouldShowOnScreen(screenObj) {
        if (!screenObj)
            return false;
        if (activeScreenName === "")
            return Quickshell.screens.length > 0 && screenObj === Quickshell.screens[0];
        return screenObj.name === activeScreenName;
    }

    function screenHeight(screenObj) {
        if (!screenObj)
            return 900;
        if (screenObj.height !== undefined)
            return screenObj.height;
        if (screenObj.geometry !== undefined && screenObj.geometry.height !== undefined)
            return screenObj.geometry.height;
        return 900;
    }

    Process {
        id: settingsctlProc
        running: false
        command: ["bash", "-lc", "settingsctl wifi status"]

        onRunningChanged: {
            if (running)
                return;
            if (store.pendingSettingsJob === "")
                return;

            store.pendingSettingsJob = "";
            store.pendingSettingsForce = false;
            store.pendingSettingsArg = "";

            if (store.settingsQueue.length > 0) {
                var next = store.settingsQueue.shift();
                runSettingsRequest(next.job, next.force, next.arg);
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                var response = store.safeJsonParse(this.text);
                var job = store.pendingSettingsJob;
                var force = store.pendingSettingsForce;
                var arg = store.pendingSettingsArg;

                if (!response || response.ok !== true || !response.data) {
                    if (response && response.ok === false && response.error && response.error.message)
                        store.setStatus(String(response.error.message));
                    if (job === "wifi list") {
                        store.wifiScanning = false;
                        store.clearModel(wifiNetworksModel);
                        store.wifiListStatus = "Scan unsuccessful: " + (response && response.error && response.error.message ? response.error.message : "unknown error");
                    } else if (job === "bt list") {
                        store.bluetoothScanning = false;
                        store.clearModel(bluetoothDevicesModel);
                        store.bluetoothListStatus = "Scan unsuccessful: " + (response && response.error && response.error.message ? response.error.message : "unknown error");
                    }
                    return;
                }

                var data = response.data;

                if (job === "wifi status") {
                    store.wifiEnabled = !!data.enabled;
                    store.networkState = data.state || "unavailable";
                    store.networkSsid = data.ssid || "";
                    store.networkSignal = data.signal === undefined ? 0 : parseInt(data.signal);
                    store.wifiInterface = data.interface || "";
                } else if (job === "wifi list") {
                    store.wifiScanning = false;
                    store.wifiInterface = data.interface || store.wifiInterface;
                    store.clearModel(wifiNetworksModel);

                    var items = data.items || [];
                    for (var i = 0; i < items.length; i++) {
                        var item = items[i];
                        wifiNetworksModel.append({
                            inUse: !!item.in_use,
                            bssid: item.name || "",
                            ssid: item.name || "",
                            signal: item.signal === undefined ? 0 : parseInt(item.signal),
                            security: item.security || ""
                        });
                    }

                    if (wifiNetworksModel.count > 0)
                        store.wifiListStatus = "Scan complete: " + wifiNetworksModel.count + " networks";
                    else
                        store.wifiListStatus = "Scan complete: no networks found";

                    if (force)
                        store.setStatus(store.wifiListStatus);
                } else if (job === "wifi toggle") {
                    if (data.enabled !== undefined)
                        store.wifiEnabled = !!data.enabled;
                    store.setStatus("Wi-Fi " + (store.wifiEnabled ? "enabled" : "disabled"));
                    store.refreshCoreStatus();
                } else if (job === "wifi connect") {
                    store.setStatus("Connected to " + arg);
                    store.refreshCoreStatus();
                    store.refreshWifiList(false);
                } else if (job === "bt status") {
                    store.bluetoothEnabled = !!data.powered;
                    store.bluetoothConnections = parseInt(data.connected_count || 0);
                } else if (job === "bt list") {
                    store.bluetoothScanning = false;
                    store.clearModel(bluetoothDevicesModel);

                    var btItems = data.items || [];
                    for (var b = 0; b < btItems.length; b++) {
                        var dev = btItems[b];
                        bluetoothDevicesModel.append({
                            address: dev.address || "",
                            connected: !!dev.connected,
                            name: dev.name || (dev.address || "Unknown")
                        });
                    }

                    if (bluetoothDevicesModel.count > 0)
                        store.bluetoothListStatus = "Scan complete: " + bluetoothDevicesModel.count + " devices";
                    else
                        store.bluetoothListStatus = "Scan complete: no devices found";

                    if (force)
                        store.setStatus(store.bluetoothListStatus);
                } else if (job === "bt toggle") {
                    if (data.powered !== undefined)
                        store.bluetoothEnabled = !!data.powered;
                    store.setStatus("Bluetooth " + (store.bluetoothEnabled ? "enabled" : "disabled"));
                    store.refreshCoreStatus();
                } else if (job === "bt connect") {
                    store.setStatus("Bluetooth connected");
                    store.refreshCoreStatus();
                    store.refreshBluetoothList(false);
                } else if (job === "bt disconnect") {
                    store.setStatus("Bluetooth disconnected");
                    store.refreshCoreStatus();
                    store.refreshBluetoothList(false);
                } else if (job === "audio status") {
                    var out = data.output || {};
                    var mic = data.mic || {};
                    store.audioMuted = !!out.muted;
                    store.audioVolume = parseInt(out.volume || 0);
                    store.micMuted = !!mic.muted;
                    store.micVolume = parseInt(mic.volume || 0);
                    store.defaultSink = data.default_sink || "";
                } else if (job === "audio list-sinks") {
                    store.clearModel(audioSinksModel);
                    var sinks = data.items || [];
                    for (var s = 0; s < sinks.length; s++) {
                        var sink = sinks[s];
                        audioSinksModel.append({
                            name: sink.name || "",
                            description: sink.description || sink.name || "",
                            volume: sink.volume === undefined ? 0 : parseInt(sink.volume)
                        });
                    }
                } else if (job === "audio set-volume") {
                    store.setStatus("Volume set to " + store.audioVolume + "%");
                    store.settingsctl("audio status");
                } else if (job === "audio set-mic-volume") {
                    store.setStatus("Mic volume set to " + store.micVolume + "%");
                    store.settingsctl("audio status");
                } else if (job === "audio set-default-sink") {
                    store.defaultSink = data.default_sink || store.defaultSink;
                    store.setStatus("Default output set");
                    store.settingsctl("audio status");
                    store.settingsctl("audio list-sinks");
                } else if (job === "audio toggle-mute") {
                    if (data.output && data.output.muted !== undefined)
                        store.audioMuted = !!data.output.muted;
                    store.setStatus(store.audioMuted ? "Output muted" : "Output unmuted");
                    store.settingsctl("audio status");
                } else if (job === "audio toggle-mic") {
                    if (data.mic && data.mic.muted !== undefined)
                        store.micMuted = !!data.mic.muted;
                    store.setStatus(store.micMuted ? "Mic muted" : "Mic unmuted");
                    store.settingsctl("audio status");
                } else if (job === "theme list") {
                    store.clearModel(themesModel);
                    var themes = data.items || [];
                    for (var t = 0; t < themes.length; t++) {
                        var th = themes[t];
                        themesModel.append({
                            name: th.name || "",
                            isCurrent: !!th.current
                        });
                        if (th.current)
                            store.currentThemeName = th.name || "";
                    }
                    if (store.selectedTheme === "" && themesModel.count > 0)
                        store.selectedTheme = themesModel.get(0).name;
                    if (store.selectedTheme !== "")
                        store.requestThemeBackgrounds(store.selectedTheme);
                    store.settingsctl("theme current");
                } else if (job === "theme backgrounds") {
                    store.clearModel(themeBackgroundsModel);
                    var bgItems = data.items || [];
                    for (var p = 0; p < bgItems.length; p++) {
                        var path = bgItems[p] || "";
                        if (path !== "")
                            themeBackgroundsModel.append({ path: path });
                    }
                    if (themeBackgroundsModel.count > 0)
                        store.themesStatus = "Loaded " + themeBackgroundsModel.count + " backgrounds";
                    else
                        store.themesStatus = "No backgrounds found in theme: " + store.selectedTheme;
                } else if (job === "theme current") {
                    store.currentThemeName = data.name || "";
                    for (var m = 0; m < themesModel.count; m++)
                        themesModel.setProperty(m, "isCurrent", themesModel.get(m).name === store.currentThemeName);
                    store.settingsctl("wallpaper status");
                } else if (job === "theme set") {
                    store.setStatus("Theme applied: " + arg);
                    store.themesStatus = "Theme applied: " + arg;
                    store.refreshThemesData();
                } else if (job === "wallpaper status") {
                    store.currentBackgroundPath = data.path || "";
                    if (store.selectedBackgroundPath === "" && store.currentBackgroundPath !== "")
                        store.selectedBackgroundPath = store.currentBackgroundPath;
                } else if (job === "wallpaper set") {
                    store.currentBackgroundPath = data.path || store.currentBackgroundPath;
                    store.selectedBackgroundPath = store.currentBackgroundPath;
                    store.setStatus("Background applied");
                    store.themesStatus = "Background applied";
                } else if (job === "system battery") {
                    store.batteryPercent = data.percent === undefined ? 0 : parseInt(data.percent);
                    store.batteryStatus = data.status || "Unknown";
                } else if (job === "system active-monitor") {
                    store.activeScreenName = data.name || "";
                    store.initialScreenResolved = true;
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                var job = store.pendingSettingsJob;
                var raw = String(this.text).trim();
                if (raw === "")
                    return;
                var errObj = store.safeJsonParse(this.text);
                var errMsg = "Operation failed";

                if (errObj && errObj.error && errObj.error.message)
                    errMsg = String(errObj.error.message);
                else
                    errMsg = raw.split("\n")[0];

                store.setStatus(errMsg);

                if (job === "wifi list") {
                    store.wifiScanning = false;
                    store.clearModel(wifiNetworksModel);
                    store.wifiListStatus = "Scan unsuccessful: " + errMsg;
                } else if (job === "bt list") {
                    store.bluetoothScanning = false;
                    store.clearModel(bluetoothDevicesModel);
                    store.bluetoothListStatus = "Scan unsuccessful: " + errMsg;
                } else if (job === "system active-monitor") {
                    store.initialScreenResolved = true;
                }
            }
        }
    }

    Timer {
        interval: 320
        running: store.wifiScanning
        repeat: true
        onTriggered: store.scanTick = (store.scanTick + 1) % 3
    }

    Timer {
        interval: 320
        running: store.bluetoothScanning
        repeat: true
        onTriggered: store.bluetoothScanTick = (store.bluetoothScanTick + 1) % 3
    }

    Timer {
        id: settingsStatusClear
        interval: 4500
        running: false
        repeat: false
        onTriggered: store.settingsStatus = ""
    }

    Component.onCompleted: {
        store.refreshCoreStatus();
        store.refreshThemesData();
    }
}
