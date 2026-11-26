import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: win
    screen: {
        var l = Quickshell.screens
        for (var i = 0; i < l.length; i++) if (l[i].name === "DP-1") return l[i]
        return l.length > 0 ? l.pop() : null
    }

    property string mode: HibikiState.activePopover
    visible: mode !== "" || dropAnim > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    margins.top: 42
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: mode !== "" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property real dropAnim: mode !== "" ? 1.0 : 0.0
    Behavior on dropAnim {
        NumberAnimation { duration: mode !== "" ? 320 : 200; easing.type: mode !== "" ? Easing.OutBack : Easing.InCubic; easing.overshoot: 1.14 }
    }

    property bool wifiOn: true
    property var wifiList: []
    property string askSsid: ""
    property string wifiStatus: ""

    property int localVol: HibikiState.stats ? HibikiState.stats.volume : 50
    property int localMic: HibikiState.stats ? HibikiState.stats.micVolume : 80
    property bool dragVol: false
    property bool dragMic: false
    property string audioTab: "sink"
    property var sinks: []
    property var sources: []
    property string defSink: ""
    property string defSource: ""

    onVisibleChanged: if (visible) { audProc.running = false; audProc.running = true }
    onModeChanged: {
        if (mode === "wifi") { askSsid = ""; wifiStatus = ""; wifiProc.running = false; wifiProc.running = true }
        else if (mode === "audio") { audProc.running = false; audProc.running = true }
    }

    Connections {
        target: HibikiState
        function onStatsChanged() {
            if (!win.dragVol && HibikiState.stats) win.localVol = HibikiState.stats.volume
            if (!win.dragMic && HibikiState.stats) win.localMic = HibikiState.stats.micVolume
        }
    }

    Process {
        id: wifiProc
        command: [Quickshell.env("HOME") + "/.config/quickshell/wifi_scan.py"]
        stdout: SplitParser { onRead: function(line) { try { var d = JSON.parse(line); win.wifiOn = d.radio; win.wifiList = d.list } catch (e) {} } }
    }
    Process {
        id: wifiConnProc
        stdout: SplitParser { onRead: function(line) { win.wifiStatus = line.trim(); wifiProc.running = false; wifiProc.running = true } }
    }
    Process {
        id: audProc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/audio_devs.py"]
        running: true
        stdout: SplitParser { onRead: function(line) { try { var j = JSON.parse(line); win.defSink = j.ds; win.defSource = j.dsrc; win.sinks = j.sinks; win.sources = j.sources } catch (e) {} } }
    }

    MouseArea { anchors.fill: parent; onClicked: HibikiState.activePopover = "" }
    Rectangle {
        id: card
        width: 340
        height: win.mode === "wifi" ? 410 : 390
        property real anchorX: win.mode === "wifi" ? (parent.width - 276) : (parent.width - 224)
        x: Math.max(14, Math.min(parent.width - width - 14, anchorX - width / 2))
        y: 6 * win.dropAnim
        opacity: Math.min(1.0, win.dropAnim * 1.6)
        scale: 0.16 + 0.84 * win.dropAnim
        transformOrigin: Item.Top
        radius: 22; color: "#ad11161f"; border.width: 1; border.color: "#aaffffff"
        focus: true
        Keys.onEscapePressed: HibikiState.activePopover = ""
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 16; spacing: 10
            visible: win.mode === "wifi"
            RowLayout {
                Layout.fillWidth: true; Layout.preferredHeight: 32; spacing: 8
                Text { text: "Сети Wi-Fi"; color: "#ffffff"; font.pixelSize: 16; font.bold: true }
                Item { Layout.fillWidth: true }
                Rectangle {
                    Layout.preferredHeight: 28; Layout.preferredWidth: 28; radius: 14
                    color: rfMa.containsMouse ? "#33ffffff" : "#18ffffff"; border.width: 1; border.color: "#44ffffff"
                    Text { anchors.centerIn: parent; text: "↻"; color: "#ffffff"; font.pixelSize: 13 }
                    MouseArea { id: rfMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { win.wifiStatus = "Поиск..."; wifiProc.running = false; wifiProc.running = true } }
                }
                Rectangle {
                    Layout.preferredHeight: 28; Layout.preferredWidth: wTgl.implicitWidth + 18; radius: 14
                    color: win.wifiOn ? "#44dcf2ff" : "#18ffffff"; border.width: 1; border.color: win.wifiOn ? "#aaffffff" : "#44ffffff"
                    Text { id: wTgl; anchors.centerIn: parent; text: win.wifiOn ? "Вкл" : "Выкл"; color: "#ffffff"; font.pixelSize: 12; font.bold: win.wifiOn }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { HibikiState.runCmd(["nmcli", "radio", "wifi", win.wifiOn ? "off" : "on"]); win.wifiOn = !win.wifiOn } }
                }
            }
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 40; radius: 12
                visible: win.askSsid !== ""; color: "#22ffffff"; border.width: 1; border.color: "#88a6e3e9"
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 6; spacing: 6
                    TextInput {
                        id: passInput; Layout.fillWidth: true; color: "#ffffff"; font.pixelSize: 12; echoMode: TextInput.Password; clip: true
                        Text { anchors.fill: parent; text: "Пароль для " + win.askSsid; color: "#88ffffff"; font.pixelSize: 12; visible: !passInput.text }
                        Keys.onReturnPressed: connBtnMa.clicked(null)
                    }
                    Rectangle {
                        Layout.preferredHeight: 28; Layout.preferredWidth: 64; radius: 9; color: "#44a6e3e9"; border.width: 1; border.color: "#88ffffff"
                        Text { anchors.centerIn: parent; text: "Войти"; color: "#ffffff"; font.pixelSize: 11; font.bold: true }
                        MouseArea {
                            id: connBtnMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { win.wifiStatus = "Подключение..."; wifiConnProc.command = ["nmcli", "dev", "wifi", "connect", win.askSsid, "password", passInput.text]; wifiConnProc.running = false; wifiConnProc.running = true; passInput.text = ""; win.askSsid = "" }
                        }
                    }
                }
            }
            Text { text: win.wifiStatus; color: "#a6e3e9"; font.pixelSize: 11; visible: win.wifiStatus !== "" }
            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true; radius: 16; color: "#14ffffff"; border.width: 1; border.color: "#38ffffff"
                Text { anchors.centerIn: parent; visible: !win.wifiOn || win.wifiList.length === 0; text: win.wifiOn ? "Сети не найдены" : "Wi-Fi отключён"; color: "#b8c8d8"; font.pixelSize: 13 }
                ListView {
                    id: wList; anchors.fill: parent; anchors.margins: 8; spacing: 6; clip: true; visible: win.wifiOn; model: win.wifiList
                    delegate: Rectangle {
                        width: wList.width; height: 40; radius: 12
                        color: modelData.active ? "#3ce6f4ff" : (nMa.containsMouse ? "#24ffffff" : "#14ffffff")
                        border.width: 1; border.color: modelData.active ? "#99ffffff" : "#26ffffff"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8
                            Text { Layout.fillWidth: true; text: modelData.ssid; color: "#ffffff"; font.pixelSize: 13; font.bold: modelData.active; elide: Text.ElideRight }
                            Text { text: modelData.sec ? "🔒" : ""; font.pixelSize: 11 }
                            Text { text: modelData.sig + "%"; color: "#a6e3e9"; font.pixelSize: 11; font.bold: true }
                        }
                        MouseArea {
                            id: nMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.active) return
                                win.wifiStatus = "Подключение к " + modelData.ssid + "..."
                                wifiConnProc.command = ["sh", "-c", "nmcli con up \"$1\" 2>/dev/null || nmcli dev wifi connect \"$1\"", "_", modelData.ssid]
                                wifiConnProc.running = false; wifiConnProc.running = true
                                if (modelData.sec) { win.askSsid = modelData.ssid; passInput.forceActiveFocus() }
                            }
                        }
                    }
                }
            }
        }
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 16; spacing: 10
            visible: win.mode === "audio"

            Text { text: "Быстрый звук"; color: "#ffffff"; font.pixelSize: 16; font.bold: true }

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 96; radius: 16; color: "#14ffffff"; border.width: 1; border.color: "#38ffffff"
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 10; spacing: 8
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        Rectangle {
                            width: 30; height: 30; radius: 10; color: HibikiState.stats.muted ? "#44ff5c7c" : "#28e6f4ff"
                            Text { anchors.centerIn: parent; text: HibikiState.stats.muted ? "🔇" : "🔊"; font.pixelSize: 14 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: HibikiState.runCmd(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"]) }
                        }
                        Item {
                            Layout.fillWidth: true; height: 18
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 8; radius: 4; color: "#26ffffff"
                                Rectangle { width: parent.width * Math.min(1, Math.max(0, win.localVol / 100)); height: parent.height; radius: 4; color: HibikiState.stats.muted ? "#ff6b8b" : "#f2f9ff" }
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                function u(mx) { var p = Math.round(Math.max(0, Math.min(100, (mx / width) * 100))); win.localVol = p; HibikiState.runCmd(["pactl", "set-sink-volume", "@DEFAULT_SINK@", p + "%"]) }
                                onPressed: (m) => { win.dragVol = true; u(m.x) }
                                onPositionChanged: (m) => { if (pressed) u(m.x) }
                                onReleased: win.dragVol = false
                            }
                        }
                        Text { text: win.localVol + "%"; color: "#ffffff"; font.pixelSize: 12; font.bold: true; Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        Rectangle {
                            width: 30; height: 30; radius: 10; color: HibikiState.stats.micMuted ? "#44ff5c7c" : "#28e6f4ff"
                            Text { anchors.centerIn: parent; text: "🎙"; font.pixelSize: 14 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: HibikiState.runCmd(["pactl", "set-source-mute", "@DEFAULT_SOURCE@", "toggle"]) }
                        }
                        Item {
                            Layout.fillWidth: true; height: 18
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 8; radius: 4; color: "#26ffffff"
                                Rectangle { width: parent.width * Math.min(1, Math.max(0, win.localMic / 100)); height: parent.height; radius: 4; color: HibikiState.stats.micMuted ? "#ff6b8b" : "#f2f9ff" }
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                function u(mx) { var p = Math.round(Math.max(0, Math.min(100, (mx / width) * 100))); win.localMic = p; HibikiState.runCmd(["pactl", "set-source-volume", "@DEFAULT_SOURCE@", p + "%"]) }
                                onPressed: (m) => { win.dragMic = true; u(m.x) }
                                onPositionChanged: (m) => { if (pressed) u(m.x) }
                                onReleased: win.dragMic = false
                            }
                        }
                        Text { text: win.localMic + "%"; color: "#ffffff"; font.pixelSize: 12; font.bold: true; Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight }
                    }
                }
            }

            // Переключатель Вывод / Ввод
            Rectangle {
                id: audSw
                Layout.fillWidth: true; Layout.preferredHeight: 34; radius: 12; color: "#16ffffff"; border.width: 1; border.color: "#38ffffff"
                property real halfW: (width - 6) / 2
                Rectangle {
                    y: 3; x: win.audioTab === "sink" ? 3 : (3 + audSw.halfW)
                    width: audSw.halfW; height: parent.height - 6; radius: 9
                    color: "#3ce6f4ff"; border.width: 1; border.color: "#88ffffff"
                    Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.06 } }
                }
                Row {
                    anchors.fill: parent; anchors.margins: 3
                    Item {
                        width: audSw.halfW; height: parent.height
                        Text { anchors.centerIn: parent; text: "Вывод (Наушники)"; color: win.audioTab === "sink" ? "#ffffff" : "#b8c8d8"; font.pixelSize: 12; font.bold: win.audioTab === "sink" }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.audioTab = "sink" }
                    }
                    Item {
                        width: audSw.halfW; height: parent.height
                        Text { anchors.centerIn: parent; text: "Ввод (Микрофон)"; color: win.audioTab === "source" ? "#ffffff" : "#b8c8d8"; font.pixelSize: 12; font.bold: win.audioTab === "source" }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.audioTab = "source" }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true; radius: 16; color: "#14ffffff"; border.width: 1; border.color: "#38ffffff"
                ListView {
                    id: sList; anchors.fill: parent; anchors.margins: 8; spacing: 6; clip: true
                    model: win.audioTab === "sink" ? win.sinks : win.sources
                    delegate: Rectangle {
                        width: sList.width; height: 36; radius: 10
                        property bool cur: win.audioTab === "sink" ? (modelData.name === win.defSink) : (modelData.name === win.defSource)
                        color: cur ? "#3ce6f4ff" : (skMa.containsMouse ? "#24ffffff" : "#12ffffff")
                        border.width: 1; border.color: cur ? "#99ffffff" : "#22ffffff"
                        Text { anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight; text: modelData.desc; color: "#ffffff"; font.pixelSize: 12; font.bold: cur }
                        MouseArea {
                            id: skMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (win.audioTab === "sink") { win.defSink = modelData.name; HibikiState.savedSink = modelData.name; HibikiState.runCmd(["pactl", "set-default-sink", modelData.name]) }
                                else { win.defSource = modelData.name; HibikiState.savedSource = modelData.name; HibikiState.runCmd(["pactl", "set-default-source", modelData.name]) }
                                HibikiState.saveState()
                            }
                        }
                    }
                }
            }
        }
    }
}
