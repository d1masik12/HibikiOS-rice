import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: root
    spacing: 12
    property var wallList: []
    property string currentWall: ""

    Process {
        id: wallsProc
        command: ["python3", "-c", "import os, json, glob; h=os.path.expanduser(\"~\"); cw=open(h+\"/.cache/hibiki-wallpaper\").read().strip() if os.path.exists(h+\"/.cache/hibiki-wallpaper\") else \"\"; dirs=[h+\"/Pictures/Wallpapers\", h+\"/Wallpapers\", h+\"/Изображения\"]; files=[]; [files.extend(glob.glob(d+\"/*.*\")) for d in dirs if os.path.isdir(d)]; imgs=[f for f in sorted(files) if f.lower().endswith((\".png\",\".jpg\",\".jpeg\",\".webp\"))]; print(json.dumps({\"cur\":cw,\"list\":imgs}))"]
        running: true
        stdout: SplitParser { onRead: function(line) { try { var d = JSON.parse(line); root.currentWall = d.cur; root.wallList = d.list } catch (e) {} } }
    }

    OneUiPlayer { Layout.fillWidth: true; Layout.preferredHeight: 122; showLyricsBtn: false }
    GridLayout {
        Layout.fillWidth: true; columns: 2; rowSpacing: 8; columnSpacing: 10
        Repeater {
            model: [
                { title: "Wi-Fi", sub: HibikiState.stats.wifiOn ? (HibikiState.stats.wifiSsid || "Включён") : "Выключен", active: HibikiState.stats.wifiOn, danger: false, cmd: ["nmcli", "radio", "wifi", HibikiState.stats.wifiOn ? "off" : "on"] },
                { title: "Bluetooth", sub: HibikiState.stats.btOn ? "Активен" : "Выключен", active: HibikiState.stats.btOn, danger: false, cmd: ["bluetoothctl", "power", HibikiState.stats.btOn ? "off" : "on"] },
                { title: "Микрофон", sub: HibikiState.stats.micMuted ? "Отключён" : "Активен", active: !HibikiState.stats.micMuted, danger: HibikiState.stats.micMuted, cmd: ["pactl", "set-source-mute", "@DEFAULT_SOURCE@", "toggle"] },
                { title: "Эквалайзер", sub: HibikiState.cavaEnabled ? "Включён" : "Выключен", active: HibikiState.cavaEnabled, danger: false, action: "cava" }
            ]
            delegate: Rectangle {
                Layout.fillWidth: true; height: 50; radius: 14
                color: HibikiState.uiTheme === "m3" ? (modelData.danger ? HibikiState.tileDangerColor : modelData.active ? HibikiState.tileActiveColor : (tileMouse.containsMouse ? HibikiState.tileHoverColor : HibikiState.tileColor)) : (modelData.danger ? "#33ff5c7c" : modelData.active ? "#33a6e3e9" : (tileMouse.containsMouse ? "#1effffff" : "#12ffffff"))
                border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: modelData.danger ? "#77ff5c7c" : modelData.active ? "#77a6e3e9" : "#24ffffff"
                scale: tileMouse.pressed ? 0.96 : (tileMouse.containsMouse ? 1.02 : 1.0)
                Behavior on scale { NumberAnimation { duration: 110 } }
                ColumnLayout {
                    anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; anchors.topMargin: 7; anchors.bottomMargin: 7; spacing: 1
                    Text { text: modelData.title; color: "#f2f6fa"; font.pixelSize: 13; font.bold: true }
                    Text { Layout.fillWidth: true; text: modelData.sub; color: modelData.danger ? "#ff9eb0" : "#9aa8b8"; font.pixelSize: 11; elide: Text.ElideRight }
                }
                MouseArea {
                    id: tileMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.action === "cava") { HibikiState.cavaEnabled = !HibikiState.cavaEnabled; HibikiState.saveState() }
                        else if (modelData.cmd) HibikiState.runCmd(modelData.cmd)
                    }
                }
            }
        }
    }
    Rectangle {
        Layout.fillWidth: true; Layout.fillHeight: true; radius: 16; color: HibikiState.uiTheme === "m3" ? "transparent" : "#12ffffff"; border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: "#24ffffff"
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 10; spacing: 8
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Обои рабочего стола"; color: "#f2f6fa"; font.pixelSize: 13; font.bold: true; Layout.fillWidth: true }
                Text {
                    text: "Карусель →"; color: HibikiState.accentColor; font.pixelSize: 12; font.bold: true
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { HibikiState.controlOpen = false; HibikiState.runCmd([Quickshell.env("HOME") + "/.local/bin/wall-carousel"]) } }
                }
            }
            ListView {
                id: wallListView
                Layout.fillWidth: true; Layout.fillHeight: true
                orientation: ListView.Horizontal; spacing: 10; clip: true; cacheBuffer: 4000
                boundsBehavior: Flickable.StopAtBounds
                NumberAnimation { id: scrollAnim; target: wallListView; property: "contentX"; duration: 180; easing.type: Easing.OutCubic }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    z: 10
                    onWheel: function(wheel) {
                        var maxX = Math.max(0, wallListView.contentWidth - wallListView.width)
                        var delta = (wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x)
                        scrollAnim.stop()
                        scrollAnim.to = Math.max(0, Math.min(maxX, wallListView.contentX - delta * 1.6))
                        scrollAnim.start()
                        wheel.accepted = true
                    }
                }
                model: root.wallList
                delegate: Item {
                    id: wCard
                    width: Math.round(height * 1.77); height: wallListView.height
                    property bool isCur: modelData === root.currentWall
                    scale: wMa.pressed ? 0.95 : (wMa.containsMouse ? 1.03 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                    Image { id: wImg; visible: false; source: "file://" + modelData; sourceSize: Qt.size(300, 170); asynchronous: true; onStatusChanged: if (status === Image.Ready) wCvs.requestPaint() }
                    Canvas {
                        id: wCvs; anchors.fill: parent
                        property bool cur: wCard.isCur
                        onCurChanged: requestPaint()
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                            ctx.save(); ctx.beginPath(); ctx.roundedRect(1, 1, width - 2, height - 2, 12, 12); ctx.closePath(); ctx.clip()
                            if (wImg.status === Image.Ready) ctx.drawImage(wImg, 0, 0, width, height)
                            else { ctx.fillStyle = "#1e2634"; ctx.fillRect(0, 0, width, height) }
                            ctx.restore()
                            ctx.beginPath(); ctx.roundedRect(1, 1, width - 2, height - 2, 12, 12)
                            ctx.lineWidth = cur ? 2.2 : 1.0; ctx.strokeStyle = cur ? HibikiState.accentColor : "#44ffffff"; ctx.stroke()
                        }
                    }
                    MouseArea {
                        id: wMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.currentWall = modelData
                            HibikiState.runCmd(["sh", "-c", "awww img \"$1\" --transition-type grow --transition-fps 165 && printf \"%s\" \"$1\" > \"$HOME/.cache/hibiki-wallpaper\"", "_", modelData])
                        }
                    }
                }
            }
        }
    }
}
