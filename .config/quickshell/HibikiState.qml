pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root
    property bool controlOpen: false
    property bool notifOpen: false
    property string activePopover: ""
    property int activeTab: 0
    property bool cavaEnabled: false
    property string cavaStyle: "bars"
    property bool lyricsEnabled: true
    property bool dndEnabled: false
    property string savedSink: ""
    property string savedSource: ""
    property string stateFile: Quickshell.env("HOME") + "/.cache/hibiki-panel-state.json"

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
                if (arr.length > 4) arr.pop()
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

    function setTab(idx) { activeTab = idx; saveState() }
    function saveState() {
        var payload = JSON.stringify({
            activeTab: activeTab, cavaEnabled: cavaEnabled, cavaStyle: cavaStyle,
            lyricsEnabled: lyricsEnabled, dndEnabled: dndEnabled,
            savedSink: savedSink, savedSource: savedSource
        })
        saveProc.command = ["sh", "-c", "printf '%s' \"$1\" > \"$2\"", "_", payload, stateFile]
saveProc.running = true
}
function runCmd(args) { cmdProc.command = args; cmdProc.running = true }

Process { id: saveProc }
Process { id: cmdProc }
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
Timer { interval: (root.controlOpen || root.notifOpen) ? 1000 : 2500; running: true; repeat: true; triggeredOnStart: true; onTriggered: pollProc.running = true }
}
