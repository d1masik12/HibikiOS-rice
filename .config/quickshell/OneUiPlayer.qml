import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

Rectangle {
    id: root
    property bool compact: false
    property bool showLyricsBtn: false
    property var player: Mpris.players.values.length > 0 ? Mpris.players.values.slice().pop() : null
    property real trackPos: player ? player.position : 0
    property real trackLen: player ? player.length : 0
    property real wavePhase: 0
    property bool isPlaying: player && player.isPlaying
    property real animAmp: isPlaying ? 3.8 : 0.0

    Behavior on animAmp { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
    onAnimAmpChanged: waveCvs.requestPaint()

    radius: 20
    color: "#cc141923"
    border.width: 1
    border.color: "#88ffffff"

    function fmtTime(sec) {
        if (!sec || sec < 0) return "0:00"
        var m = Math.floor(sec / 60)
        var s = Math.floor(sec % 60)
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    Timer {
        interval: 40
        running: root.visible && (root.isPlaying || root.animAmp > 0.05)
        repeat: true
        onTriggered: {
            if (root.isPlaying) root.wavePhase += 0.16
            if (root.player) {
                root.trackPos = root.player.position
                root.trackLen = root.player.length
            }
            waveCvs.requestPaint()
        }
    }

    onTrackPosChanged: waveCvs.requestPaint()
    onTrackLenChanged: waveCvs.requestPaint()

    Image {
        id: bgArt
        visible: false
        source: root.player && root.player.trackArtUrl ? root.player.trackArtUrl : ""
        onStatusChanged: bgCvs.requestPaint()
        onSourceChanged: bgCvs.requestPaint()
    }

    Canvas {
        id: bgCvs
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.save()
            ctx.beginPath()
            ctx.roundedRect(0, 0, width, height, 20, 20)
            ctx.closePath()
            ctx.clip()

            if (bgArt.status === Image.Ready) {
                ctx.globalAlpha = 0.42
                ctx.drawImage(bgArt, 0, 0, width, height)
                ctx.globalAlpha = 1.0
            }

            var g = ctx.createLinearGradient(0, 0, 0, height)
            g.addColorStop(0.0, "#7710151e")
            g.addColorStop(0.55, "#aa10151e")
            g.addColorStop(1.0, "#dd0d1118")
            ctx.fillStyle = g
            ctx.fillRect(0, 0, width, height)
            ctx.restore()
        }
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.compact ? 12 : 14
        spacing: root.compact ? 6 : 8

        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Text {
                Layout.fillWidth: true
                text: root.player && root.player.trackTitle ? root.player.trackTitle : "Ничего не играет"
                color: "#ffffff"
                font.pixelSize: root.compact ? 14 : 15
                font.bold: true
                elide: Text.ElideRight
            }
            Text {
                text: root.player && root.player.trackArtist ? root.player.trackArtist : "Hibiki Audio"
                color: "#d4e4f4"
                font.pixelSize: 12
                elide: Text.ElideRight
                Layout.maximumWidth: 165
            }
        }

        Item {
            id: seekArea
            Layout.fillWidth: true
            height: 24
            property real ratio: root.trackLen > 0 ? Math.min(1.0, Math.max(0.0, root.trackPos / root.trackLen)) : 0.0

            Canvas {
                id: waveCvs
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    var cy = height / 2
                    var pad = 8
                    var usableW = Math.max(10, width - pad * 2)
                    var thumbX = pad + usableW * seekArea.ratio
                    var amp = root.animAmp

                    ctx.beginPath()
                    ctx.moveTo(thumbX, cy)
                    ctx.lineTo(width - pad, cy)
                    ctx.lineWidth = 2.5
                    ctx.lineCap = "round"
                    ctx.strokeStyle = "#44ffffff"
                    ctx.stroke()

                    var grad = ctx.createLinearGradient(pad, 0, Math.max(pad + 1, thumbX), 0)
                    grad.addColorStop(0.0, "#88a6e3e9")
                    grad.addColorStop(0.6, "#dde8f7ff")
                    grad.addColorStop(1.0, "#ffffff")

                    ctx.beginPath()
                    for (var x = pad; x <= thumbX; x += 2) {
                        var y = cy + Math.sin((x - pad) * 0.16 - root.wavePhase) * amp
                        if (x === pad) ctx.moveTo(x, y)
                        else ctx.lineTo(x, y)
                    }
                    ctx.lineWidth = 3.0
                    ctx.lineCap = "round"
                    ctx.strokeStyle = grad
                    ctx.stroke()

                    ctx.beginPath()
                    ctx.arc(thumbX, cy, 8.5, 0, Math.PI * 2)
                    ctx.fillStyle = "#33ffffff"
                    ctx.fill()

                    ctx.beginPath()
                    ctx.arc(thumbX, cy, 5.5, 0, Math.PI * 2)
                    ctx.fillStyle = "#161c26"
                    ctx.fill()
                    ctx.lineWidth = 2.4
                    ctx.strokeStyle = "#ffffff"
                    ctx.stroke()
                }
            }

            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                function seek(mx) {
                    if (!root.player || root.trackLen <= 0) return
                    var r = Math.max(0.0, Math.min(1.0, (mx - 8) / Math.max(1, width - 16)))
                    var t = r * root.trackLen
                    root.player.position = t
                    root.trackPos = t
                    waveCvs.requestPaint()
                }
                onPressed: (m) => seek(m.x)
                onPositionChanged: (m) => { if (pressed) seek(m.x) }
            }
        }

        Item {
            Layout.fillWidth: true
            height: 34

            Text {
                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                text: root.fmtTime(root.trackPos); color: "#d8e6f3"; font.pixelSize: 11; font.bold: true
            }

            Row {
                anchors.centerIn: parent
                spacing: 14
                Repeater {
                    model: ListModel { ListElement { act: "prev" } ListElement { act: "play" } ListElement { act: "next" } }
                    delegate: Rectangle {
                        width: act === "play" ? 36 : 32
                        height: act === "play" ? 36 : 32
                        radius: width / 2
                        color: act === "play" ? (bMa.containsMouse ? "#66ffffff" : "#44ffffff") : (bMa.containsMouse ? "#28ffffff" : "transparent")
                        border.width: act === "play" ? 1 : 0
                        border.color: "#88ffffff"
                        scale: bMa.pressed ? 0.88 : (bMa.containsMouse ? 1.06 : 1.0)
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

                        Canvas {
                            anchors.centerIn: parent; width: 13; height: 13
                            property bool playing: root.isPlaying
                            onPlayingChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d"); ctx.clearRect(0, 0, 13, 13); ctx.fillStyle = "#ffffff"
                                if (act === "prev") { ctx.fillRect(1.5, 1.5, 2, 10); ctx.beginPath(); ctx.moveTo(11.5, 1.5); ctx.lineTo(4.5, 6.5); ctx.lineTo(11.5, 11.5); ctx.fill() }
                                else if (act === "next") { ctx.fillRect(9.5, 1.5, 2, 10); ctx.beginPath(); ctx.moveTo(1.5, 1.5); ctx.lineTo(8.5, 6.5); ctx.lineTo(1.5, 11.5); ctx.fill() }
                                else if (playing) { ctx.fillRect(2.5, 1.5, 3, 10); ctx.fillRect(7.5, 1.5, 3, 10) }
                                else { ctx.beginPath(); ctx.moveTo(2.5, 1.5); ctx.lineTo(11.5, 6.5); ctx.lineTo(2.5, 11.5); ctx.fill() }
                            }
                        }
                        MouseArea { id: bMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (!root.player) return; if (act === "prev") root.player.previous(); else if (act === "play") root.player.togglePlaying(); else root.player.next() } }
                    }
                }
            }

            Rectangle {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                visible: root.showLyricsBtn
                height: 26; width: lTxt.implicitWidth + 16; radius: 13
                color: HibikiState.lyricsEnabled ? "#44e6f4ff" : "#1effffff"
                border.width: 1; border.color: HibikiState.lyricsEnabled ? "#99ffffff" : "#44ffffff"
                scale: lyMa.pressed ? 0.92 : 1.0
                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on scale { NumberAnimation { duration: 90 } }
                Text { id: lTxt; anchors.centerIn: parent; text: "Текст"; color: "#ffffff"; font.pixelSize: 11; font.bold: HibikiState.lyricsEnabled }
                MouseArea { id: lyMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { HibikiState.lyricsEnabled = !HibikiState.lyricsEnabled; HibikiState.saveState() } }
            }

            Text {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                visible: !root.showLyricsBtn
                text: root.fmtTime(root.trackLen); color: "#b8c8d8"; font.pixelSize: 11
            }
        }
    }
}
