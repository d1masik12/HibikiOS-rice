import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root
    property int localVol: HibikiState.stats ? HibikiState.stats.volume : 50
    property int localMic: HibikiState.stats ? HibikiState.stats.micVolume : 80
    property bool draggingVol: false
    property bool draggingMic: false

    property var sinks: []
    property var sources: []
    property string defaultSink: ""
    property string defaultSource: ""
    property string drawerMode: ""

    property real morph: drawerMode !== "" ? 1.0 : 0.0
    Behavior on morph {
        NumberAnimation {
            duration: 260
            easing.type: Easing.OutBack
            easing.overshoot: 1.08
        }
    }

    function findDesc(list, name, fallback) {
        for (var i = 0; i < list.length; i++) {
            if (list[i].name === name) return list[i].desc
        }
        return fallback
    }

    Connections {
        target: HibikiState
        function onStatsChanged() {
            if (!root.draggingVol && HibikiState.stats) root.localVol = HibikiState.stats.volume
            if (!root.draggingMic && HibikiState.stats) root.localMic = HibikiState.stats.micVolume
        }
    }

    Process {
        id: devProc
        command: ["python3", "-c", "import subprocess, json; ds=subprocess.getoutput(\"pactl get-default-sink\").strip(); dsrc=subprocess.getoutput(\"pactl get-default-source\").strip(); s_out=subprocess.getoutput(\"pactl -f json list sinks\"); src_out=subprocess.getoutput(\"pactl -f json list sources\"); s_data=json.loads(s_out) if s_out.startswith(\"[\") else []; src_data=json.loads(src_out) if src_out.startswith(\"[\") else []; sinks=[{\"name\":x.get(\"name\",\"\"),\"desc\":x.get(\"description\",x.get(\"name\",\"\"))} for x in s_data]; sources=[{\"name\":x.get(\"name\",\"\"),\"desc\":x.get(\"description\",x.get(\"name\",\"\"))} for x in src_data if not x.get(\"name\",\"\").endswith(\".monitor\")]; print(json.dumps({\"ds\":ds,\"dsrc\":dsrc,\"sinks\":sinks,\"sources\":sources}, ensure_ascii=False))"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    var j = JSON.parse(line)
                    root.defaultSink = j.ds; root.defaultSource = j.dsrc
                    root.sinks = j.sinks; root.sources = j.sources
                } catch (e) {}
            }
        }
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: 12
        opacity: 1.0 - root.morph
        scale: 1.0 - 0.08 * root.morph
        visible: opacity > 0.01

        Rectangle {
            Layout.fillWidth: true; height: 114; radius: 16; color: HibikiState.cardColor; border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: "#26ffffff"
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 12; spacing: 10
                RowLayout {
                    Layout.fillWidth: true; spacing: 10
                    Rectangle {
                        width: 34; height: 34; radius: 11
                        color: HibikiState.stats.muted ? "#38ff5c7c" : "#26a6e3e9"
                        border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: HibikiState.stats.muted ? "#77ff5c7c" : "#55a6e3e9"
                        Text { anchors.centerIn: parent; text: HibikiState.stats.muted ? "🔇" : "🔊"; font.pixelSize: 15 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: HibikiState.runCmd(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"]) }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        RowLayout {
                            Text { text: "Общая громкость"; color: "#f2f6fa"; font.pixelSize: 13; font.bold: true; Layout.fillWidth: true }
                            Text { text: root.localVol + "%"; color: HibikiState.accentColor; font.pixelSize: 13; font.bold: true }
                        }
                        Item {
                            Layout.fillWidth: true; height: 18
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 8; radius: 4; color: "#22ffffff"
                                Rectangle { width: parent.width * Math.min(1.0, Math.max(0.0, root.localVol / 100.0)); height: parent.height; radius: 4; color: HibikiState.stats.muted ? "#ff6b8b" : HibikiState.accentColor }
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                function upd(mx) { var p = Math.round(Math.max(0, Math.min(100, (mx / width) * 100))); root.localVol = p; HibikiState.runCmd(["pactl", "set-sink-volume", "@DEFAULT_SINK@", p + "%"]) }
                                onPressed: (m) => { root.draggingVol = true; upd(m.x) }
                                onPositionChanged: (m) => { if (pressed) upd(m.x) }
                                onReleased: root.draggingVol = false
                            }
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 10
                    Rectangle {
                        width: 34; height: 34; radius: 11
                        color: HibikiState.stats.micMuted ? "#38ff5c7c" : "#26a6e3e9"
                        border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: HibikiState.stats.micMuted ? "#77ff5c7c" : "#55a6e3e9"
                        Text { anchors.centerIn: parent; text: "🎙"; font.pixelSize: 15 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: HibikiState.runCmd(["pactl", "set-source-mute", "@DEFAULT_SOURCE@", "toggle"]) }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        RowLayout {
                            Text { text: "Микрофон"; color: "#f2f6fa"; font.pixelSize: 13; font.bold: true; Layout.fillWidth: true }
                            Text { text: root.localMic + "%"; color: HibikiState.accentColor; font.pixelSize: 13; font.bold: true }
                        }
                        Item {
                            Layout.fillWidth: true; height: 18
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 8; radius: 4; color: "#22ffffff"
                                Rectangle { width: parent.width * Math.min(1.0, Math.max(0.0, root.localMic / 100.0)); height: parent.height; radius: 4; color: HibikiState.stats.micMuted ? "#ff6b8b" : HibikiState.accentColor }
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                function upd(mx) { var p = Math.round(Math.max(0, Math.min(100, (mx / width) * 100))); root.localMic = p; HibikiState.runCmd(["pactl", "set-source-volume", "@DEFAULT_SOURCE@", p + "%"]) }
                                onPressed: (m) => { root.draggingMic = true; upd(m.x) }
                                onPositionChanged: (m) => { if (pressed) upd(m.x) }
                                onReleased: root.draggingMic = false
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true; spacing: 10
            Repeater {
                model: ListModel {
                    ListElement { mode: "sink"; title: "Вывод звука" }
                    ListElement { mode: "source"; title: "Ввод (Микрофон)" }
                }
                delegate: Rectangle {
                    Layout.fillWidth: true; height: 64; radius: 15
                    color: dMa.containsMouse ? "#24a6e3e9" : "#14ffffff"
                    border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: dMa.containsMouse ? "#66a6e3e9" : "#26ffffff"
                    scale: dMa.pressed ? 0.97 : 1.0
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on scale { NumberAnimation { duration: 90 } }
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 12; spacing: 8
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 2
                            Text { text: title; color: "#9aa8b8"; font.pixelSize: 11 }
                            Text {
                                Layout.fillWidth: true; color: "#f2f6fa"; font.pixelSize: 13; font.bold: true; elide: Text.ElideRight
                                text: mode === "sink" ? root.findDesc(root.sinks, root.defaultSink, "По умолчанию") : root.findDesc(root.sources, root.defaultSource, "По умолчанию")
                            }
                        }
                        Text { text: "›"; color: HibikiState.accentColor; font.pixelSize: 20; font.bold: true }
                    }
                    MouseArea { id: dMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { devProc.running = true; root.drawerMode = mode } }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; height: 84; radius: 16; color: HibikiState.cardColor; border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: "#26ffffff"
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 12; spacing: 8
                Text { text: "Стиль эквалайзера"; color: "#f2f6fa"; font.pixelSize: 13; font.bold: true }
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    Repeater {
                        model: ListModel {
                            ListElement { key: "bars"; label: "Столбики" }
                            ListElement { key: "wave"; label: "Волна" }
                            ListElement { key: "mirror"; label: "Зеркало" }
                            ListElement { key: "ring"; label: "Кольцо" }
                        }
                        delegate: Rectangle {
                            Layout.fillWidth: true; height: 34; radius: 10
                            property bool active: HibikiState.cavaStyle === key
                            color: active ? "#38a6e3e9" : (eqMa.containsMouse ? "#1effffff" : "#10ffffff")
                            border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: active ? "#77a6e3e9" : "#22ffffff"
                            Text { anchors.centerIn: parent; text: label; color: active ? "#ffffff" : "#9aa8b8"; font.pixelSize: 12; font.bold: active }
                            MouseArea { id: eqMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { HibikiState.cavaStyle = key; HibikiState.saveState() } }
                        }
                    }
                }
            }
        }
        Item { Layout.fillHeight: true }
    }
    Rectangle {
        anchors.fill: parent
        radius: 16
        color: "#16ffffff"
        border.width: HibikiState.uiTheme === "m3" ? 0 : 1
        border.color: "#55a6e3e9"
        opacity: root.morph
        scale: 0.90 + 0.10 * root.morph
        visible: opacity > 0.01

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 14; spacing: 10
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true; color: "#f2f6fa"; font.pixelSize: 14; font.bold: true
                    text: root.drawerMode === "sink" ? "Выбор устройства вывода" : "Выбор микрофона (ввода)"
                }
                Rectangle {
                    width: 30; height: 30; radius: 15; color: cMa.containsMouse ? "#33a6e3e9" : "#1effffff"; border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: "#44a6e3e9"
                    Text { anchors.centerIn: parent; text: "✕"; color: "#e6f2f8"; font.pixelSize: 12 }
                    MouseArea { id: cMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.drawerMode = "" }
                }
            }
            ListView {
                Layout.fillWidth: true; Layout.fillHeight: true; spacing: 8; clip: true
                model: root.drawerMode === "sink" ? root.sinks : root.sources
                delegate: Rectangle {
                    width: parent ? parent.width : 440; height: 44; radius: 12
                    property bool isCur: root.drawerMode === "sink" ? (modelData.name === root.defaultSink) : (modelData.name === root.defaultSource)
                    color: isCur ? "#38a6e3e9" : (itemMa.containsMouse ? "#1effffff" : "#10ffffff")
                    border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: isCur ? "#77a6e3e9" : "#22ffffff"
                    scale: itemMa.pressed ? 0.98 : 1.0
                    Behavior on scale { NumberAnimation { duration: 90 } }
                    Text {
                        anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14
                        verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight
                        text: modelData.desc; color: isCur ? "#ffffff" : "#b8c6d6"; font.pixelSize: 13; font.bold: isCur
                    }
                    MouseArea {
                        id: itemMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.drawerMode === "sink") {
                                root.defaultSink = modelData.name
                                HibikiState.savedSink = modelData.name
                                HibikiState.runCmd(["pactl", "set-default-sink", modelData.name])
                            } else {
                                root.defaultSource = modelData.name
                                HibikiState.savedSource = modelData.name
                                HibikiState.runCmd(["pactl", "set-default-source", modelData.name])
                            }
                            HibikiState.saveState()
                            root.drawerMode = ""
                        }
                    }
                }
            }
        }
    }
}
