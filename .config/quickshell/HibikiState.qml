pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root
    property bool controlOpen: false
    property bool notifOpen: false
    property bool settingsOpen: false
    property bool launcherOpen: false
    property string activePopover: ""
    property int activeTab: 0
    property int settingsTab: 0

    property bool cavaEnabled: false
    property string cavaStyle: "bars"
    property bool lyricsEnabled: true

    property bool dndEnabled: false
    property int toastTimeout: 5000
    property int maxPopups: 4
    property string notifScreen: "DP-1"
    property string uiScreen: "DP-1"
    property string cavaScreen: "all"
    property string activeOutput: "DP-1"

    onControlOpenChanged: if (controlOpen) refreshFocusedOutput()
    onNotifOpenChanged: if (notifOpen) refreshFocusedOutput()
    onSettingsOpenChanged: if (settingsOpen) refreshFocusedOutput()
    onLauncherOpenChanged: if (launcherOpen) refreshFocusedOutput()

    function refreshFocusedOutput() {
        focusOutProc.running = false
        focusOutProc.running = true
    }

    property var detectedOutputs: [
        { name: "DP-1", desc: "Основной дисплей", hz: "165 Hz" },
        { name: "HDMI-A-1", desc: "Второй дисплей", hz: "60 Hz" }
    ]
    property var monitorConfigs: ({
        "DP-1": { enabled: true, scale: 1.0, vrr: true },
        "HDMI-A-1": { enabled: true, scale: 1.0, vrr: false }
    })
    property bool dp1Vrr: true
    property real dp1Scale: 1.0
    property bool hdmiEnabled: true
    property real hdmiScale: 1.0
    property string xkbOptions: "grp:alt_shift_toggle"
    property string trackLayout: "global"
    property real mouseSpeed: 0.0
    property string mouseAccel: "flat"
    property int niriGaps: 10
    property int niriFocusWidth: 2
    property int niriCornerRadius: 16
    property string glassAlpha: "ad"
    property string paletteMode: "preset"
    property string presetId: "ice"
    property string lastWallPath: ""
    property color accentColor: "#a6e3e9"
    property color accentAltColor: "#89dceb"
    Behavior on accentColor { ColorAnimation { duration: 450; easing.type: Easing.OutCubic } }
    Behavior on accentAltColor { ColorAnimation { duration: 450; easing.type: Easing.OutCubic } }

    readonly property var palettePresets: ([
        { id: "ice",    name: "Ambient Ice",  c1: "#a6e3e9", c2: "#89dceb" },
        { id: "arctic", name: "Arctic Blue",  c1: "#89b4fa", c2: "#74c7ec" },
        { id: "sakura", name: "Sakura Frost", c1: "#f5c2e7", c2: "#cba6f7" },
        { id: "mint",   name: "Mint Aurora",  c1: "#94e2d5", c2: "#a6e3a1" },
        { id: "amber",  name: "Sunset Amber", c1: "#fab387", c2: "#f9e2af" }
    ])

    function selectPreset(pid) {
        paletteMode = "preset";
        presetId = pid;
        for (var i = 0; i < palettePresets.length; i++) {
            if (palettePresets[i].id === pid) {
                accentColor = palettePresets[i].c1;
                accentAltColor = palettePresets[i].c2;
                break;
            }
        }
        saveState();
        applyNiriConfig();
    }

    function enableChameleon(force) {
        paletteMode = "chameleon";
        if (force) lastWallPath = "";
        chameleonProc.running = false;
        chameleonProc.running = true;
        saveState();
    }
    property string niriCenterCol: "never"
    property bool niriShadow: true
    property string uiTheme: "ice" // "ice" | "m3" | "liquid"

    property color glassColor: {
        if (uiTheme === "m3") return "#ff1c1b1f";
        if (uiTheme === "liquid") return "#5c141c28";
        return "#" + glassAlpha + "11161f";
    }
    Behavior on glassColor { ColorAnimation { duration: 380; easing.type: Easing.OutCubic } }

    property color cardColor: {
        if (uiTheme === "m3") return "#252b36";
        if (uiTheme === "liquid") return "#20ffffff";
        return "#14ffffff";
    }
    Behavior on cardColor { ColorAnimation { duration: 380; easing.type: Easing.OutCubic } }

    // Плитки Control Center в стиле Material 3 (тональные контейнеры)
    readonly property color tileColor: "#211f26"
    readonly property color tileHoverColor: "#2b2930"
    readonly property color tileActiveColor: "#4f378b"
    readonly property color tileDangerColor: "#8c1d18"

    // Акцент переключателей и ползунков: фиолетовый в M3, прежний в остальных темах
    readonly property color m3Primary: "#d0bcff"
    readonly property color toggleAccent: uiTheme === "m3" ? m3Primary : accentColor
    readonly property color sliderFill: uiTheme === "m3" ? m3Primary : "#f2f9ff"

    property color panelBorderColor: {
        if (uiTheme === "m3") return "#28ffffff";
        if (uiTheme === "liquid") return "#e6ffffff";
        return "#aaffffff";
    }
    Behavior on panelBorderColor { ColorAnimation { duration: 380; easing.type: Easing.OutCubic } }

    property real panelBorderWidth: uiTheme === "m3" ? 0 : (uiTheme === "liquid" ? 1.5 : 1.0)
    Behavior on panelBorderWidth { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    property int panelRadius: uiTheme === "liquid" ? 34 : (uiTheme === "m3" ? 28 : 24)
    Behavior on panelRadius { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }

    property int cardRadius: uiTheme === "liquid" ? 24 : (uiTheme === "m3" ? 26 : 18)
    Behavior on cardRadius { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }

    property color specularTop: {
        if (uiTheme === "m3") return "#06ffffff";
        if (uiTheme === "liquid") return "#5cffffff";
        return "#32ffffff";
    }
    Behavior on specularTop { ColorAnimation { duration: 380 } }

    property color specularMid: {
        if (uiTheme === "m3") return "#02ffffff";
        if (uiTheme === "liquid") return "#1ce6f5ff";
        return "#10e6f5ff";
    }
    Behavior on specularMid { ColorAnimation { duration: 380 } }

    function setUiTheme(themeId) {
        uiTheme = themeId;
        if (themeId === "m3") {
            niriCornerRadius = 20;
        } else if (themeId === "liquid") {
            niriCornerRadius = 24;
        } else {
            niriCornerRadius = 16;
        }
        saveState();
        applyNiriConfig();
    }

    property real glassDimOpacity: 0.0
    Behavior on glassDimOpacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

    property string savedSink: ""
    property string savedSource: ""
    property string stateFile: Quickshell.env("HOME") + "/.cache/hibiki-panel-state.json"
    property string niriGenFile: Quickshell.env("HOME") + "/.config/niri/hibiki-generated.kdl"

    property var popupItems: []
    property int notifCount: notifServer.trackedNotifications.values.length

    NotificationServer {
        id: notifServer
        keepOnReload: true
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        onNotification: function(n) {
            n.tracked = true
            if (!root.dndEnabled && !root.notifOpen) {
                var arr = root.popupItems.slice()
                arr.unshift(n)
                while (arr.length > root.maxPopups) arr.pop()
                root.popupItems = arr
            }
        }
    }

    function dismissPopup(n) {
        var arr = []
        for (var i = 0; i < popupItems.length; i++) {
            if (popupItems[i] !== n) arr.push(popupItems[i])
        }
        popupItems = arr
    }

    function clearAllNotifs() {
        var list = notifServer.trackedNotifications.values.slice()
        for (var i = 0; i < list.length; i++) list[i].dismiss()
        popupItems = []
    }
    property alias notifications: notifServer.trackedNotifications
    property var stats: ({
        volume: 50, muted: false, micVolume: 80, micMuted: false,
        cpu: 0, gpu: 0, ram: 0, cpuTemp: 0, gpuTemp: 0,
        ramUsedGb: 0, ramTotalGb: 64, diskPct: 0, diskUsedGb: 0, diskTotalGb: 0,
        vramUsedMb: 0, vramTotalMb: 12288, uptime: "",
        wifiOn: true, wifiSsid: "", btOn: false
    })

    function getMonCfg(name) {
        if (monitorConfigs && monitorConfigs[name]) return monitorConfigs[name];
        return { enabled: true, scale: 1.0, vrr: false };
    }
    function setMonProp(name, key, val) {
        var copy = JSON.parse(JSON.stringify(monitorConfigs || {}));
        if (!copy[name]) copy[name] = { enabled: true, scale: 1.0, vrr: false };
        copy[name][key] = val;
        monitorConfigs = copy;
        saveState();
        applyNiriConfig();
    }
    function screenChoiceLabels() {
        var outs = detectedOutputs || [];
        if (outs.length <= 1) return outs.length === 1 ? [outs.name] : ["DP-1"];
        var arr = [outs.length === 2 ? "Оба" : ("Все (" + outs.length + ")")];
        for (var i = 0; i < outs.length; i++) arr.push(outs[i].name);
        return arr;
    }
    function screenChoiceValues() {
        var outs = detectedOutputs || [];
        if (outs.length <= 1) return ["all"];
        var arr = ["all"];
        for (var i = 0; i < outs.length; i++) arr.push(outs[i].name);
        return arr;
    }
    function refreshOutputs() {
        outListProc.running = false;
        outListProc.running = true;
    }

    function setTab(idx) { activeTab = idx; saveState() }

    function applyNiriConfig() {
        var q = String.fromCharCode(34);
        var nl = String.fromCharCode(10);
        var kdl = "// Auto-generated by Hibiki UI Settings" + nl;
        var outs = root.detectedOutputs || [];
        for (var i = 0; i < outs.length; i++) {
            var nm = outs[i].name;
            var cfg = root.getMonCfg(nm);
            kdl += "output " + q + nm + q + " {" + nl;
            if (!cfg.enabled) kdl += "    off" + nl;
            kdl += "    scale " + Number(cfg.scale || 1.0).toFixed(2) + nl;
            if (cfg.vrr) kdl += "    variable-refresh-rate on-demand=true" + nl;
            kdl += "}" + nl + nl;
        }
        kdl += "input {" + nl
            + "    keyboard {" + nl
            + "        xkb {" + nl
            + "            layout " + q + "us,ru" + q + nl
            + "            options " + q + root.xkbOptions + q + nl
            + "        }" + nl
            + "        track-layout " + q + root.trackLayout + q + nl
            + "    }" + nl
            + "    mouse {" + nl
            + "        accel-speed " + root.mouseSpeed.toFixed(2) + nl
            + "        accel-profile " + q + root.mouseAccel + q + nl
            + "    }" + nl
            + "}" + nl + nl
            + "layout {" + nl
            + "    gaps " + root.niriGaps + nl
            + "    center-focused-column " + q + root.niriCenterCol + q + nl
            + (root.niriShadow ? "    shadow { on; }" + nl : "")
            + "    focus-ring {" + nl
            + "        width " + root.niriFocusWidth + nl
            + "        active-gradient from=" + q + root.accentColor.toString() + q + " to=" + q + root.accentAltColor.toString() + q + " angle=45" + nl
            + "    }" + nl
            + "}" + nl + nl
            + "window-rule {" + nl
            + "    geometry-corner-radius " + root.niriCornerRadius + nl
            + "    clip-to-geometry true" + nl
            + "}" + nl;

        niriWriteProc.command = ['sh', '-c', 'printf %s \"$1\" > \"$2\"', '_', kdl, niriGenFile];
        niriWriteProc.running = true;
        root.runCmd(["niri", "msg", "action", "load-config-file"]);
    }

    function saveState() {
        var payload = JSON.stringify({
            activeTab: activeTab, cavaEnabled: cavaEnabled, cavaStyle: cavaStyle,
            lyricsEnabled: lyricsEnabled, dndEnabled: dndEnabled,
            toastTimeout: toastTimeout, maxPopups: maxPopups, notifScreen: notifScreen, uiScreen: uiScreen, cavaScreen: cavaScreen,
            monitorConfigs: monitorConfigs, dp1Vrr: dp1Vrr, dp1Scale: dp1Scale, hdmiEnabled: hdmiEnabled, hdmiScale: hdmiScale,
            xkbOptions: xkbOptions, trackLayout: trackLayout,
            mouseSpeed: mouseSpeed, mouseAccel: mouseAccel,
            niriGaps: niriGaps, niriFocusWidth: niriFocusWidth, niriCornerRadius: niriCornerRadius, uiTheme: uiTheme, glassAlpha: glassAlpha, paletteMode: paletteMode, presetId: presetId, accentColor: accentColor.toString(), accentAltColor: accentAltColor.toString(), niriCenterCol: niriCenterCol, niriShadow: niriShadow,
            savedSink: savedSink, savedSource: savedSource
        });
        saveProc.command = ['sh', '-c', 'printf %s "$1" > "$2"', '_', payload, stateFile];
        saveProc.running = true;
    }

    function runCmd(args) { cmdProc.command = args; cmdProc.running = true }

    Process { id: saveProc }
    Process { id: niriWriteProc }
    Process { id: cmdProc }
    Process {
        id: chameleonProc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/wall_palette.py"]
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    var d = JSON.parse(line);
                    if (d.wall && d.wall !== root.lastWallPath) {
                        root.lastWallPath = d.wall;
                        if (d.accent) root.accentColor = d.accent;
                        if (d.accentAlt) root.accentAltColor = d.accentAlt;
                        root.applyNiriConfig();
                    }
                } catch (e) {}
            }
        }
    }
    Timer {
        interval: 2000
        running: root.paletteMode === "chameleon"
        repeat: true
        triggeredOnStart: true
        onTriggered: { chameleonProc.running = false; chameleonProc.running = true }
    }
    Process {
        id: outListProc
        running: true
        command: ["sh", "-c", "niri msg -j outputs | tr -d '
'"]
        stdout: SplitParser {
            onRead: function(raw) {
                try {
                    var obj = JSON.parse(raw);
                    var keys = Object.keys(obj);
                    var res = [];
                    for (var i = 0; i < keys.length && res.length < 3; i++) {
                        var k = keys[i];
                        var o = obj[k];
                        var hz = "";
                        if (o.modes && o.current_mode !== null && o.modes[o.current_mode]) {
                            hz = Math.round(o.modes[o.current_mode].refresh_rate / 1000) + " Hz";
                        }
                        var desc = ((o.make || "") + " " + (o.model || "")).trim();
                        res.push({ name: k, desc: desc || "Дисплей", hz: hz });
                    }
                    if (res.length > 0) root.detectedOutputs = res;
                } catch (e) {}
            }
        }
    }
    Process {
        id: focusOutProc
        command: ["niri", "msg", "-j", "focused-output"]
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    var d = JSON.parse(line)
                    if (d && d.name) root.activeOutput = d.name
                } catch (e) {}
            }
        }
    }
    Process {
        id: loadProc
        command: ["cat", root.stateFile]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    var d = JSON.parse(line)
                    if (d.activeTab !== undefined) root.activeTab = d.activeTab
                    if (d.cavaEnabled !== undefined) root.cavaEnabled = d.cavaEnabled
                    if (d.cavaStyle !== undefined) root.cavaStyle = d.cavaStyle
                    if (d.lyricsEnabled !== undefined) root.lyricsEnabled = d.lyricsEnabled
                    if (d.dndEnabled !== undefined) root.dndEnabled = d.dndEnabled
                    if (d.toastTimeout !== undefined) root.toastTimeout = d.toastTimeout
                    if (d.maxPopups !== undefined) root.maxPopups = d.maxPopups
                    if (d.notifScreen !== undefined) root.notifScreen = d.notifScreen
                    if (d.uiScreen !== undefined) root.uiScreen = d.uiScreen
                    if (d.cavaScreen !== undefined) root.cavaScreen = d.cavaScreen
                    if (d.monitorConfigs !== undefined) root.monitorConfigs = d.monitorConfigs
                    if (d.dp1Vrr !== undefined) root.dp1Vrr = d.dp1Vrr
                    if (d.dp1Scale !== undefined) root.dp1Scale = d.dp1Scale
                    if (d.hdmiEnabled !== undefined) root.hdmiEnabled = d.hdmiEnabled
                    if (d.hdmiScale !== undefined) root.hdmiScale = d.hdmiScale
                    if (d.xkbOptions !== undefined) root.xkbOptions = d.xkbOptions
                    if (d.trackLayout !== undefined) root.trackLayout = d.trackLayout
                    if (d.mouseSpeed !== undefined) root.mouseSpeed = d.mouseSpeed
                    if (d.mouseAccel !== undefined) root.mouseAccel = d.mouseAccel
                    if (d.niriGaps !== undefined) root.niriGaps = d.niriGaps
                    if (d.niriFocusWidth !== undefined) root.niriFocusWidth = d.niriFocusWidth
                    if (d.niriCornerRadius !== undefined) root.niriCornerRadius = d.niriCornerRadius
                    if (d.uiTheme !== undefined) root.uiTheme = d.uiTheme
                    if (d.glassAlpha !== undefined) root.glassAlpha = d.glassAlpha
                    if (d.paletteMode !== undefined) root.paletteMode = d.paletteMode
                    if (d.presetId !== undefined) root.presetId = d.presetId
                    if (d.accentColor !== undefined) root.accentColor = d.accentColor
                    if (d.accentAltColor !== undefined) root.accentAltColor = d.accentAltColor
                    if (d.niriCenterCol !== undefined) root.niriCenterCol = d.niriCenterCol
                    if (d.niriShadow !== undefined) root.niriShadow = d.niriShadow
                    if (d.savedSink) { root.savedSink = d.savedSink; root.runCmd(["pactl", "set-default-sink", d.savedSink]) }
                    if (d.savedSource) { root.savedSource = d.savedSource; root.runCmd(["pactl", "set-default-source", d.savedSource]) }
                } catch (e) {}
            }
        }
    }
    Process {
        id: pollProc
        command: [Quickshell.env("HOME") + "/.config/quickshell/poll.sh"]
        stdout: SplitParser { onRead: function(line) { try { root.stats = JSON.parse(line) } catch (e) {} } }
    }
    Timer { interval: (root.controlOpen || root.notifOpen || root.settingsOpen) ? 1000 : 2500; running: true; repeat: true; triggeredOnStart: true; onTriggered: pollProc.running = true }
}
