import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Mpris

PanelWindow {
    id: visWin

    screen: {
        var list = Quickshell.screens
        for (var i = 0; i < list.length; i++) {
            if (list[i].name === "DP-1") return list[i]
        }
        return list.length > 0 ? list.pop() : null
    }

    property var player: Mpris.players.values.length > 0 ? Mpris.players.values.slice().pop() : null
    property string trackKey: player ? ((player.trackTitle || "") + "||" + (player.trackArtist || "")) : ""
    property var lyricLines: []
    property string curLine: ""
    property string nextLine: ""

    property bool audioActive: player && player.isPlaying
    visible: (HibikiState.cavaEnabled && audioActive) || (HibikiState.lyricsEnabled && curLine !== "" && audioActive)
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region {}

    property var bars: []
    property real fadeAnim: HibikiState.cavaEnabled ? 1.0 : 0.0
    Behavior on fadeAnim { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

    onTrackKeyChanged: {
        lyricLines = []
        curLine = ""
        nextLine = ""
        if (player && player.trackTitle && HibikiState.lyricsEnabled) {
            lyricsProc.command = [Quickshell.env("HOME") + "/.config/quickshell/lyrics.py", player.trackTitle, player.trackArtist || "", String(player.length || 0)]
            lyricsProc.running = false
            lyricsProc.running = true
        }
    }

    Connections {
        target: HibikiState
        function onLyricsEnabledChanged() {
            if (HibikiState.lyricsEnabled && visWin.player && visWin.player.trackTitle) {
                lyricsProc.command = [Quickshell.env("HOME") + "/.config/quickshell/lyrics.py", visWin.player.trackTitle, visWin.player.trackArtist || "", String(visWin.player.length || 0)]
                lyricsProc.running = false
                lyricsProc.running = true
            } else if (!HibikiState.lyricsEnabled) {
                visWin.curLine = ""
                visWin.nextLine = ""
            }
        }
    }

    Process {
        id: lyricsProc
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    var d = JSON.parse(line)
                    visWin.lyricLines = d.lines || []
                } catch (e) { visWin.lyricLines = [] }
            }
        }
    }

    Timer {
        interval: 120
        running: HibikiState.lyricsEnabled && visWin.lyricLines.length > 0 && visWin.player && visWin.player.isPlaying
        repeat: true
        onTriggered: {
            var pos = (visWin.player ? visWin.player.position : 0) + 0.25
            var arr = visWin.lyricLines
            var idx = -1
            for (var i = 0; i < arr.length; i++) {
                if (pos >= arr[i].t) idx = i
                else break
            }
            visWin.curLine = idx >= 0 ? arr[idx].text : ""
            visWin.nextLine = (idx >= 0 && idx + 1 < arr.length) ? arr[idx + 1].text : ""
        }
    }

    Process {
        id: cavaProc
        command: ["cava", "-p", Quickshell.env("HOME") + "/.config/quickshell/cava.conf"]
        running: HibikiState.cavaEnabled && visWin.audioActive
        stdout: SplitParser {
            onRead: function(line) {
                var parts = line.split(";")
                var arr = []
                for (var i = 0; i < parts.length; i++) {
                    if (parts[i] !== "") arr.push(parseInt(parts[i]) || 0)
                }
                if (arr.length > 0) {
                    visWin.bars = arr
                    cvs.requestPaint()
                }
            }
        }
    }
    Canvas {
        id: cvs
        anchors.fill: parent
        opacity: visWin.fadeAnim

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            var b = visWin.bars
            var n = b.length
            if (n === 0) return
            var style = HibikiState.cavaStyle || "bars"
            var gap = 5

            if (style === "bars") {
                var maxH = 190
                var bw = Math.max(3, (width - gap * (n - 1)) / n)
                var r = bw / 2
                var grad = ctx.createLinearGradient(0, height - maxH, 0, height)
                grad.addColorStop(0.0, "#ccf2f9ff")
                grad.addColorStop(0.45, "#99a6e3e9")
                grad.addColorStop(1.0, "#22a6e3e9")
                ctx.fillStyle = grad
                for (var i = 0; i < n; i++) {
                    var h = Math.max(4, (b[i] / 100.0) * maxH)
                    var x = i * (bw + gap)
                    var y = height - h
                    var rad = Math.min(r, h)
                    ctx.beginPath()
                    ctx.moveTo(x, height); ctx.lineTo(x, y + rad)
                    ctx.arcTo(x, y, x + rad, y, rad); ctx.lineTo(x + bw - rad, y)
                    ctx.arcTo(x + bw, y, x + bw, y + rad, rad); ctx.lineTo(x + bw, height)
                    ctx.closePath(); ctx.fill()
                }
            } else if (style === "wave") {
                var maxH = 200
                var step = width / Math.max(1, n - 1)
                var grad = ctx.createLinearGradient(0, height - maxH, 0, height)
                grad.addColorStop(0.0, "#88a6e3e9")
                grad.addColorStop(1.0, "#08a6e3e9")
                ctx.beginPath(); ctx.moveTo(0, height)
                for (var i = 0; i < n; i++) {
                    var x = i * step; var y = height - Math.max(4, (b[i] / 100.0) * maxH)
                    if (i === 0) ctx.lineTo(x, y)
                    else { var px = (i - 1) * step; var py = height - Math.max(4, (b[i - 1] / 100.0) * maxH); ctx.quadraticCurveTo(px, py, (px + x) / 2, (py + y) / 2) }
                }
                ctx.lineTo(width, height); ctx.closePath(); ctx.fillStyle = grad; ctx.fill()
                ctx.lineWidth = 2.2; ctx.strokeStyle = "#cca6e3e9"; ctx.stroke()
            } else if (style === "mirror") {
                var baseY = height - 155
                var maxH = 95
                var bw = Math.max(3, (width - gap * (n - 1)) / n)
                ctx.fillStyle = "#99a6e3e9"
                for (var i = 0; i < n; i++) {
                    var h = Math.max(2, (b[i] / 100.0) * maxH)
                    var x = i * (bw + gap)
                    ctx.beginPath(); ctx.roundedRect(x, baseY - h, bw, h * 2, bw / 2, bw / 2); ctx.fill()
                }
            } else if (style === "ring") {
                var cx = width / 2; var cy = height / 2; var baseR = 165; var maxLen = 105
                ctx.lineWidth = 3.2; ctx.lineCap = "round"; ctx.strokeStyle = "#bba6e3e9"
                for (var i = 0; i < n; i++) {
                    var ang = (i / n) * Math.PI * 2 - Math.PI / 2
                    var len = 4 + (b[i] / 100.0) * maxLen
                    ctx.beginPath()
                    ctx.moveTo(cx + Math.cos(ang) * baseR, cy + Math.sin(ang) * baseR)
                    ctx.lineTo(cx + Math.cos(ang) * (baseR + len), cy + Math.sin(ang) * (baseR + len))
                    ctx.stroke()
                }
            }
        }
    }

    Item {
        id: lyricBox
        property string style: HibikiState.cavaStyle || "bars"
        property bool showLyrics: HibikiState.lyricsEnabled && visWin.curLine !== "" && visWin.player && visWin.player.isPlaying

        width: style === "ring" ? 270 : Math.min(920, parent.width * 0.72)
        height: lyrCol.implicitHeight
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: style === "ring" ? parent.verticalCenter : undefined
        anchors.bottom: style === "ring" ? undefined : parent.bottom
        anchors.bottomMargin: style === "mirror" ? 18 : 210

        opacity: showLyrics ? 1.0 : 0.0
        scale: showLyrics ? 1.0 : 0.95
        Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        Column {
            id: lyrCol
            width: parent.width
            spacing: 4

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: visWin.curLine
                color: "#f4faff"
                font.pixelSize: lyricBox.style === "ring" ? 18 : 22
                font.bold: true
                style: Text.Outline
                styleColor: "#990b0e14"
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                visible: visWin.nextLine !== "" && lyricBox.style !== "mirror"
                text: visWin.nextLine
                color: "#88b8d4e3"
                font.pixelSize: lyricBox.style === "ring" ? 13 : 15
                style: Text.Outline
                styleColor: "#770b0e14"
            }
        }
    }
}
