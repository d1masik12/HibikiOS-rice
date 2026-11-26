import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Mpris

Scope {
    id: visWin
    property var player: Mpris.players.values.length > 0 ? Mpris.players.values.slice().pop() : null
    property bool audioActive: player && player.isPlaying
    property var bars: []
    property int frameTick: 0
    property real fadeAnim: HibikiState.cavaEnabled ? 1.0 : 0.0
    Behavior on fadeAnim { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

    Process {
        id: cavaProc
        command: ["cava", "-p", Quickshell.env("HOME") + "/.config/quickshell/cava.conf"]
        running: HibikiState.cavaEnabled && visWin.audioActive
        stdout: SplitParser {
            onRead: function(line) {
                var parts = line.split(";")
                var arr = []
                for (var i = 0; i < parts.length; i++) if (parts[i] !== "") arr.push(parseInt(parts[i]) || 0)
                if (arr.length > 0) { visWin.bars = arr; visWin.frameTick++ }
            }
        }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            visible: HibikiState.cavaEnabled && visWin.audioActive && (HibikiState.cavaScreen === "all" || (screen && screen.name === HibikiState.cavaScreen))
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}

            Canvas {
                id: cvs
                anchors.fill: parent
                opacity: visWin.fadeAnim
                property int tick: visWin.frameTick
                onTickChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                    var b = visWin.bars; var n = b.length; if (n === 0) return
                    var style = HibikiState.cavaStyle || "bars"; var gap = 5
                    if (style === "bars") {
                        var maxH = 190; var bw = Math.max(3, (width - gap * (n - 1)) / n); var r = bw / 2
                        var grad = ctx.createLinearGradient(0, height - maxH, 0, height)
                        grad.addColorStop(0.0, "#ccf2f9ff"); grad.addColorStop(0.45, "#99a6e3e9"); grad.addColorStop(1.0, "#22a6e3e9")
                        ctx.fillStyle = grad
                        for (var i = 0; i < n; i++) {
                            var h = Math.max(4, (b[i] / 100.0) * maxH); var x = i * (bw + gap); var y = height - h; var rad = Math.min(r, h)
                            ctx.beginPath(); ctx.moveTo(x, height); ctx.lineTo(x, y + rad); ctx.arcTo(x, y, x + rad, y, rad); ctx.lineTo(x + bw - rad, y); ctx.arcTo(x + bw, y, x + bw, y + rad, rad); ctx.lineTo(x + bw, height); ctx.closePath(); ctx.fill()
                        }
                    } else if (style === "wave") {
                        var maxH = 200; var step = width / Math.max(1, n - 1)
                        var grad = ctx.createLinearGradient(0, height - maxH, 0, height)
                        grad.addColorStop(0.0, "#88a6e3e9"); grad.addColorStop(1.0, "#08a6e3e9")
                        ctx.beginPath(); ctx.moveTo(0, height)
                        for (var i = 0; i < n; i++) {
                            var x = i * step; var y = height - Math.max(4, (b[i] / 100.0) * maxH)
                            if (i === 0) ctx.lineTo(x, y)
                            else { var px = (i - 1) * step; var py = height - Math.max(4, (b[i - 1] / 100.0) * maxH); ctx.quadraticCurveTo(px, py, (px + x) / 2, (py + y) / 2) }
                        }
                        var lastY = height - Math.max(4, (b[n - 1] / 100.0) * maxH); ctx.lineTo(width, lastY); ctx.lineTo(width, height); ctx.closePath(); ctx.fillStyle = grad; ctx.fill()
                        ctx.lineWidth = 2.2; ctx.strokeStyle = "#cca6e3e9"; ctx.stroke()
                    } else if (style === "mirror") {
                        var baseY = height - 155; var maxH = 95; var bw = Math.max(3, (width - gap * (n - 1)) / n)
                        ctx.fillStyle = "#99a6e3e9"
                        for (var i = 0; i < n; i++) {
                            var h = Math.max(2, (b[i] / 100.0) * maxH); var x = i * (bw + gap)
                            ctx.beginPath(); ctx.roundedRect(x, baseY - h, bw, h * 2, bw / 2, bw / 2); ctx.fill()
                        }
                    } else if (style === "ring") {
                        var cx = width / 2; var cy = height / 2; var baseR = 165; var maxLen = 105
                        ctx.lineWidth = 3.2; ctx.lineCap = "round"; ctx.strokeStyle = "#bba6e3e9"
                        for (var i = 0; i < n; i++) {
                            var ang = (i / n) * Math.PI * 2 - Math.PI / 2; var len = 4 + (b[i] / 100.0) * maxLen
                            ctx.beginPath(); ctx.moveTo(cx + Math.cos(ang) * baseR, cy + Math.sin(ang) * baseR); ctx.lineTo(cx + Math.cos(ang) * (baseR + len), cy + Math.sin(ang) * (baseR + len)); ctx.stroke()
                        }
                    }
                }
            }
        }
    }
}
