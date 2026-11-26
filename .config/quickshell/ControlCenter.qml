import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

Scope {
  Variants {
    model: Quickshell.screens
    PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    property bool screenMatch: screen && (HibikiState.uiScreen === "all" ? screen.name === HibikiState.activeOutput : screen.name === HibikiState.uiScreen)
    visible: screenMatch && (HibikiState.controlOpen || dropAnim > 0.01)
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: (HibikiState.controlOpen && screenMatch) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property real dropAnim: HibikiState.controlOpen ? 1.0 : 0.0
    Behavior on dropAnim {
        NumberAnimation {
            duration: HibikiState.controlOpen ? 340 : 220
            easing.type: HibikiState.controlOpen ? Easing.OutBack : Easing.InCubic
            easing.overshoot: 1.15
        }
    }

    property int avatarVer: 0
    Process {
        id: pickAvatarProc
        command: ["sh", "-c", "f=$(zenity --file-selection --title=\"Выбор аватара\" --file-filter=\"Images | *.png *.jpg *.jpeg *.webp\" 2>/dev/null); [ -n \"$f\" ] && cp \"$f\" \"$HOME/.face\" && echo ok"]
        stdout: SplitParser { onRead: function(line) { if (line.trim() === "ok") win.avatarVer += 1 } }
    }
        MouseArea { anchors.fill: parent; onClicked: HibikiState.controlOpen = false }

    Rectangle {
        id: panel
        width: 540; height: 540
        anchors.horizontalCenter: parent.horizontalCenter
        y: -2 + 58 * win.dropAnim
        opacity: Math.min(1.0, win.dropAnim * 1.35)
        scale: 0.72 + 0.28 * win.dropAnim
        transformOrigin: Item.Top
        radius: 48 - 24 * Math.min(1.0, win.dropAnim)
        color: HibikiState.glassColor
        border.width: HibikiState.panelBorderWidth
        border.color: HibikiState.panelBorderColor
        clip: true
        Rectangle {
            anchors.fill: parent; radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: HibikiState.specularTop }
                GradientStop { position: 0.25; color: HibikiState.specularMid }
                GradientStop { position: 1.0; color: "#04a6e3e9" }
            }
        }
        focus: true
        Keys.onEscapePressed: HibikiState.controlOpen = false
        MouseArea { anchors.fill: parent }
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 18; spacing: 14
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Item {
                    width: 54; height: 54
                    Image { id: rawAvatar; source: "file://" + Quickshell.env("HOME") + "/.face?v=" + win.avatarVer; visible: false; onStatusChanged: if (status === Image.Ready) avatarCanvas.requestPaint() }
                    Canvas {
                        id: avatarCanvas; anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                            ctx.save(); ctx.beginPath(); ctx.arc(width/2, height/2, width/2 - 1, 0, Math.PI * 2); ctx.closePath(); ctx.clip()
                            if (rawAvatar.status === Image.Ready) ctx.drawImage(rawAvatar, 0, 0, width, height)
                            ctx.restore()
                            ctx.beginPath(); ctx.arc(width/2, height/2, width/2 - 1, 0, Math.PI * 2); ctx.lineWidth = 1.5; ctx.strokeStyle = "#88a6e3e9"; ctx.stroke()
                        }
                    }
                    Rectangle {
                        anchors.fill: parent; radius: 27; color: "#aa0e1117"; opacity: avMa.containsMouse ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                        Text { anchors.centerIn: parent; text: "✎"; color: HibikiState.accentColor; font.pixelSize: 18; font.bold: true }
                    }
                    MouseArea { id: avMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pickAvatarProc.running = true }
                }
                ColumnLayout {
                    spacing: 2
                    Text { text: "Hibiki UI"; color: "#f2f6fa"; font.pixelSize: 17; font.bold: true }
                    Text { text: (HibikiState.stats && HibikiState.stats.uptime) ? ("Аптайм: " + HibikiState.stats.uptime) : "Arch Linux • Niri • 165Hz"; color: "#9aa8b8"; font.pixelSize: 12 }
                }
                Item { Layout.fillWidth: true }
                Row {
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    spacing: 8
                    Repeater {
                        model: ListModel {
                            ListElement { kind: "settings"; cmdStr: ""; danger: false }
                            ListElement { kind: "lock"; cmdStr: "loginctl lock-session"; danger: false }
                            ListElement { kind: "sleep"; cmdStr: "systemctl suspend"; danger: false }
                            ListElement { kind: "power"; cmdStr: "systemctl poweroff"; danger: true }
                        }
                        delegate: Rectangle {
                            width: 38; height: 38; radius: 19
                            color: pMa.containsMouse ? (danger ? "#44ff5c7c" : "#33a6e3e9") : "#16ffffff"
                            border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: danger ? "#66ff5c7c" : "#33a6e3e9"
                            scale: pMa.pressed ? 0.92 : (pMa.containsMouse ? 1.05 : 1.0)
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                            Canvas {
                                anchors.centerIn: parent; width: 16; height: 16
                                onPaint: {
                                    var ctx = getContext("2d"); ctx.clearRect(0, 0, 16, 16)
                                    ctx.strokeStyle = danger ? "#ff9eb0" : "#e6f2f8"; ctx.lineWidth = 1.6; ctx.lineCap = "round"
                                    if (kind === "settings") { ctx.beginPath(); ctx.arc(8, 8, 3.6, 0, Math.PI * 2); ctx.stroke(); ctx.beginPath(); ctx.arc(8, 8, 1.3, 0, Math.PI * 2); ctx.fillStyle = ctx.strokeStyle; ctx.fill(); for (var a = 0; a < 6; a++) { var ang = a * Math.PI / 3; ctx.beginPath(); ctx.moveTo(8 + Math.cos(ang)*3.8, 8 + Math.sin(ang)*3.8); ctx.lineTo(8 + Math.cos(ang)*5.5, 8 + Math.sin(ang)*5.5); ctx.stroke(); } }
                                    else if (kind === "lock") { ctx.strokeRect(3.5, 7.5, 9, 6.5); ctx.beginPath(); ctx.arc(8, 7.5, 3, Math.PI, 0); ctx.stroke() }
                                    else if (kind === "sleep") { ctx.beginPath(); ctx.arc(8.5, 8, 5.2, 0.4 * Math.PI, 1.75 * Math.PI); ctx.stroke() }
                                    else { ctx.beginPath(); ctx.arc(8, 8.5, 5.2, -0.32 * Math.PI, 1.32 * Math.PI); ctx.stroke(); ctx.beginPath(); ctx.moveTo(8, 2.5); ctx.lineTo(8, 7.5); ctx.stroke() }
                                }
                            }
                            MouseArea { id: pMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { HibikiState.controlOpen = false; if (kind === "settings") { HibikiState.settingsOpen = true } else { HibikiState.runCmd(["sh", "-c", cmdStr]) } } }
                        }
                    }
                }
            }
            Rectangle {
                id: tabBarBox
                Layout.fillWidth: true; height: 44; radius: HibikiState.uiTheme === "m3" ? 12 : Math.min(HibikiState.cardRadius, 22); color: HibikiState.uiTheme === "m3" ? "#e62b2930" : "#18ffffff"; border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: "#44ffffff"
                property real slotW: (width - 8) / 3

                Rectangle {
                    y: 4
                    x: 4 + HibikiState.activeTab * tabBarBox.slotW
                    width: tabBarBox.slotW
                    height: parent.height - 8
                    radius: 11
                    color: "#3ce6f4ff"
                    border.width: HibikiState.uiTheme === "m3" ? 0 : 1
                    border.color: "#88ffffff"
                    Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.06 } }
                }

                Row {
                    anchors.fill: parent; anchors.margins: 4
                    Repeater {
                        model: ListModel {
                            ListElement { title: "Основное" }
                            ListElement { title: "Звук" }
                            ListElement { title: "Система" }
                        }
                        delegate: Item {
                            width: tabBarBox.slotW; height: tabBarBox.height - 8
                            property bool isActive: HibikiState.activeTab === index
                            Text { anchors.centerIn: parent; text: title; color: isActive ? "#ffffff" : "#b8c8d8"; font.pixelSize: 14; font.bold: isActive }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: HibikiState.setTab(index) }
                        }
                    }
                }
            }
            Rectangle {
                id: tabViewport
                Layout.fillWidth: true; Layout.fillHeight: true; radius: HibikiState.uiTheme === "m3" ? 16 : HibikiState.cardRadius; color: HibikiState.uiTheme === "m3" ? "transparent" : "#0dffffff"; border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: "#22a6e3e9"
                clip: true

                Row {
                    id: tabTrack
                    height: tabViewport.height
                    x: -HibikiState.activeTab * tabViewport.width
                    Behavior on x {
                        NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
                    }

                    Item {
                        width: tabViewport.width; height: tabViewport.height
                        Loader { anchors.fill: parent; anchors.margins: 14; source: "TabMain.qml" }
                    }
                    Item {
                        width: tabViewport.width; height: tabViewport.height
                        Loader { anchors.fill: parent; anchors.margins: 14; source: "TabAudio.qml" }
                    }
                    Item {
                        width: tabViewport.width; height: tabViewport.height
                        Loader { anchors.fill: parent; anchors.margins: 14; source: "TabPerf.qml" }
                    }
                }
            }
        }
    }
    IpcHandler { target: "panel"; function toggle() { HibikiState.controlOpen = !HibikiState.controlOpen } }
}
  }
}
