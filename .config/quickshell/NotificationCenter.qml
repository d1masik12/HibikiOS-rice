import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Mpris

Scope {
    id: root
    property var player: Mpris.players.values.length > 0 ? Mpris.players.values.slice().pop() : null
    property var mainScreen: {
        var list = Quickshell.screens
        for (var i = 0; i < list.length; i++) if (list[i].name === "DP-1") return list[i]
        return list.length > 0 ? list.pop() : null
    }

    PanelWindow {
        id: drawerWin
        screen: root.mainScreen
        visible: HibikiState.notifOpen || slideAnim > 0.01
        anchors { top: true; bottom: true; left: true; right: true }
        margins.top: 42
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: HibikiState.notifOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        property real slideAnim: HibikiState.notifOpen ? 1.0 : 0.0
        property bool clearingAll: false
        Behavior on slideAnim { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        Timer { id: clearAllTimer; interval: 300; onTriggered: { HibikiState.clearAllNotifs(); drawerWin.clearingAll = false } }
        MouseArea { anchors.fill: parent; onClicked: HibikiState.notifOpen = false }
        Rectangle {
            id: sheet
            width: 410
            anchors.top: parent.top; anchors.bottom: parent.bottom
            anchors.topMargin: 10; anchors.bottomMargin: 14
            x: parent.width - width - 14 + (1.0 - drawerWin.slideAnim) * (width + 30)
            opacity: Math.min(1.0, drawerWin.slideAnim * 1.4)
            radius: 24; color: "#ad11161f"; border.width: 1; border.color: "#aaffffff"
            focus: true
            Keys.onEscapePressed: HibikiState.notifOpen = false
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 16; spacing: 12
                RowLayout {
                    Layout.fillWidth: true; Layout.preferredHeight: 34; spacing: 8
                    Text { text: "Уведомления"; color: "#ffffff"; font.pixelSize: 17; font.bold: true }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        Layout.preferredHeight: 32; Layout.preferredWidth: dndRow.implicitWidth + 22; radius: 12
                        color: HibikiState.dndEnabled ? "#44dcf2ff" : (dndMa.containsMouse ? "#28ffffff" : "#18ffffff")
                        border.width: 1; border.color: HibikiState.dndEnabled ? "#aaffffff" : "#44ffffff"
                        scale: dndMa.pressed ? 0.93 : 1.0
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on scale { NumberAnimation { duration: 110 } }
                        Row {
                            id: dndRow; anchors.centerIn: parent; spacing: 6
                            Rectangle { width: 7; height: 7; radius: 3.5; anchors.verticalCenter: parent.verticalCenter; color: HibikiState.dndEnabled ? "#a6e3e9" : "#66ffffff"; Behavior on color { ColorAnimation { duration: 200 } } }
                            Text { text: HibikiState.dndEnabled ? "Тихий: вкл" : "Тихий"; color: HibikiState.dndEnabled ? "#ffffff" : "#d0deec"; font.pixelSize: 12; font.bold: HibikiState.dndEnabled }
                        }
                        MouseArea { id: dndMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { HibikiState.dndEnabled = !HibikiState.dndEnabled; HibikiState.saveState() } }
                    }
                    Rectangle {
                        Layout.preferredHeight: 32; Layout.preferredWidth: clrTxt.implicitWidth + 18; radius: 12
                        visible: HibikiState.notifCount > 0
                        color: clrMa.containsMouse ? "#44ff5c7c" : "#18ffffff"
                        border.width: 1; border.color: "#66ff5c7c"
                        Text { id: clrTxt; anchors.centerIn: parent; text: "Очистить"; color: "#ffb8c6"; font.pixelSize: 12; font.bold: true }
                        MouseArea {
                            id: clrMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (drawerWin.clearingAll) return
                                drawerWin.clearingAll = true
                                particleCvs.burst(0, Math.min(particleCvs.height, Math.max(90, HibikiState.notifCount * 84)), 260)
                                clearAllTimer.running = true
                            }
                        }
                    }
                }
                OneUiPlayer { Layout.fillWidth: true; Layout.preferredHeight: 116; compact: true; visible: root.player !== null }
                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true; radius: 18; color: "#14ffffff"; border.width: 1; border.color: "#38ffffff"
                    Text {
                        anchors.centerIn: parent
                        opacity: (HibikiState.notifCount === 0 && !particleTimer.running) ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                        text: "Нет новых уведомлений"; color: "#b8c8d8"; font.pixelSize: 14
                    }
                    ListView {
                        id: nList; anchors.fill: parent; anchors.margins: 10; spacing: 8; clip: true
                        model: HibikiState.notifications
                        delegate: Item {
                            id: cardWrap
                            required property var modelData
                            property bool dying: drawerWin.clearingAll
                            property real baseH: cardCol.implicitHeight + 20
                            width: nList.width
                            height: dying ? 0 : baseH
                            opacity: dying ? 0.0 : 1.0
                            scale: dying ? 0.88 : 1.0
                            Behavior on height { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                            Timer { id: singleDieTimer; interval: 270; onTriggered: cardWrap.modelData.dismiss() }
                            Rectangle {
                                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                height: cardWrap.baseH; radius: 15; color: "#1cffffff"; border.width: 1; border.color: "#44ffffff"
                                ColumnLayout {
                                    id: cardCol
                                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 10; spacing: 5
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: cardWrap.modelData.appName || "Система"; color: "#dff3ff"; font.pixelSize: 11; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight }
                                        Text {
                                            text: "✕"; color: "#c8d6e5"; font.pixelSize: 12
                                            MouseArea {
                                                anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (cardWrap.dying) return
                                                    cardWrap.dying = true
                                                    particleCvs.burst(Math.max(0, cardWrap.y - nList.contentY), cardWrap.baseH, 90)
                                                    singleDieTimer.running = true
                                                }
                                            }
                                        }
                                    }
                                    Text { Layout.fillWidth: true; text: cardWrap.modelData.summary || ""; color: "#ffffff"; font.pixelSize: 13; font.bold: true; wrapMode: Text.WordWrap; visible: text !== "" }
                                    Text { Layout.fillWidth: true; text: cardWrap.modelData.body || ""; color: "#d2dfec"; font.pixelSize: 12; wrapMode: Text.WordWrap; visible: text !== "" }
                                }
                            }
                        }
                    }
                    Canvas {
                        id: particleCvs
                        anchors.fill: parent
                        property var pts: []
                        function burst(yStart, spanH, count) {
                            var arr = pts.slice()
                            for (var i = 0; i < count; i++) {
                                arr.push({ x: 10 + Math.random() * Math.max(20, width - 20), y: yStart + Math.random() * Math.max(20, spanH), vx: (Math.random() - 0.5) * 3.0, vy: -0.5 - Math.random() * 2.2, sz: 0.9 + Math.random() * 1.4, life: 1.0, ice: Math.random() > 0.35 })
                            }
                            pts = arr; particleTimer.running = true
                        }
                        Timer {
                            id: particleTimer; interval: 16; repeat: true; running: false
                            onTriggered: {
                                var a = particleCvs.pts; var alive = []
                                for (var i = 0; i < a.length; i++) {
                                    var p = a[i]; p.x += p.vx; p.y += p.vy; p.vy -= 0.03; p.life -= 0.025
                                    if (p.life > 0.02) alive.push(p)
                                }
                                particleCvs.pts = alive; particleCvs.requestPaint()
                                if (alive.length === 0) running = false
                            }
                        }
                        onPaint: {
                            var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                            for (var i = 0; i < pts.length; i++) {
                                var p = pts[i]; ctx.globalAlpha = Math.max(0, p.life); ctx.fillStyle = p.ice ? "#a6e3e9" : "#ffffff"
                                ctx.beginPath(); ctx.arc(p.x, p.y, p.sz * p.life, 0, Math.PI * 2); ctx.fill()
                            }
                            ctx.globalAlpha = 1.0
                        }
                    }
                }
            }
        }
    }
    PanelWindow {
        id: popupWin
        screen: root.mainScreen
        visible: HibikiState.popupItems.length > 0 && !HibikiState.notifOpen && !HibikiState.dndEnabled
        anchors { top: true; right: true }
        margins.top: 50; margins.right: 14
        implicitWidth: 360; implicitHeight: popCol.implicitHeight + 8
        color: "transparent"; exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay; WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Column {
            id: popCol; width: parent.width; spacing: 8
            Repeater {
                model: HibikiState.popupItems
                delegate: Rectangle {
                    id: toastBox
                    required property var modelData
                    property bool closing: false
                    property bool shown: false
                    Component.onCompleted: shown = true
                    property real life: 1.0
                    width: popCol.width
                    height: (closing || !shown) ? 0 : (pInner.implicitHeight + 22)
                    radius: 16; color: "#8218202c"; border.width: 1; border.color: "#99ffffff"
                    opacity: (closing || !shown) ? 0.0 : 1.0
                    scale: (closing || !shown) ? 0.88 : 1.0
                    Behavior on height { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    onLifeChanged: toastBarCvs.requestPaint()
                    NumberAnimation on life { from: 1.0; to: 0.0; duration: 4800; running: !popMa.containsMouse && !toastBox.closing; onFinished: { toastBox.closing = true; toastByeTimer.running = true } }
                    Timer { id: toastByeTimer; interval: 240; onTriggered: HibikiState.dismissPopup(toastBox.modelData) }
                    Canvas {
                        id: toastBarCvs; anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height); ctx.save()
                            ctx.beginPath(); ctx.roundedRect(1, 1, width - 2, height - 2, 15, 15); ctx.closePath(); ctx.clip()
                            ctx.fillStyle = "#88a6e3e9"; ctx.fillRect(0, height - 2.5, width * life, 2.5); ctx.restore()
                        }
                    }
                    ColumnLayout {
                        id: pInner; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 11; spacing: 3
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: toastBox.modelData.appName || "Уведомление"; color: "#dff3ff"; font.pixelSize: 11; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight }
                            Text { text: "✕"; color: "#c8d6e5"; font.pixelSize: 12 }
                        }
                        Text { Layout.fillWidth: true; text: toastBox.modelData.summary || ""; color: "#ffffff"; font.pixelSize: 13; font.bold: true; wrapMode: Text.WordWrap; visible: text !== "" }
                        Text { Layout.fillWidth: true; text: toastBox.modelData.body || ""; color: "#d2dfec"; font.pixelSize: 12; wrapMode: Text.WordWrap; visible: text !== "" }
                    }
                    MouseArea { id: popMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { HibikiState.dismissPopup(toastBox.modelData); HibikiState.notifOpen = true } }
                }
            }
        }
    }
    IpcHandler { target: "notif"; function toggle() { HibikiState.notifOpen = !HibikiState.notifOpen } }
}
