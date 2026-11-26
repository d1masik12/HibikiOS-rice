import QtQuick
import QtQuick.Layouts

Flickable {
    id: lookTab
    contentHeight: col.implicitHeight
    clip: true

    component BlockCard: Rectangle {
        default property alias content: inner.data
        Layout.fillWidth: true
        implicitHeight: inner.implicitHeight + 24
        radius: HibikiState.cardRadius; color: HibikiState.cardColor; border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: HibikiState.uiTheme === "liquid" ? "#66ffffff" : "#33ffffff"
        ColumnLayout { id: inner; anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 } spacing: 10 }
    }

    component ChipBar: Row {
        id: cb
        property var opts: []
        property var vals: []
        property var cur
        signal picked(var v)
        spacing: 6
        Repeater {
            model: cb.opts.length
            delegate: Rectangle {
                required property int index
                property bool act: cb.vals[index] === cb.cur
                height: 28; width: t.implicitWidth + 20; radius: 10
                color: act ? "#44a6e3e9" : (ma.containsMouse ? "#26ffffff" : "#16ffffff")
                border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: act ? HibikiState.accentColor : "#33ffffff"
                Text { id: t; anchors.centerIn: parent; text: cb.opts[index]; color: act ? "#ffffff" : "#b8c8d8"; font.pixelSize: 12; font.bold: act }
                MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: cb.picked(cb.vals[index]) }
            }
        }
    }

    component TogglePill: Rectangle {
        id: tp
        property bool on: false
        signal switched(bool v)
        width: 46; height: 26; radius: 13
        color: on ? (HibikiState.uiTheme === "m3" ? "#554f378b" : "#55a6e3e9") : "#22ffffff"
        border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: on ? HibikiState.toggleAccent : "#44ffffff"
        Rectangle {
            width: 18; height: 18; radius: 9; y: 3
            x: tp.on ? parent.width - width - 4 : 4
            color: tp.on ? HibikiState.toggleAccent : "#b8c7d9"
            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tp.switched(!tp.on) }
    }

    ColumnLayout {
        id: col; width: parent.width; spacing: 12

                Text { text: "Стиль интерфейса (Дизайн-система)"; color: HibikiState.accentColor; font.pixelSize: 13; font.bold: true }
        BlockCard {
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Repeater {
                    model: [
                        { id: "ice",    title: "Ambient Ice",  sub: "Оригинал • Матовый лёд", bg: "#ad11161f", brd: "#aaffffff", rad: 16 },
                        { id: "m3",     title: "Material You (бета)",   sub: "Тональный • Плотный",     bg: "#f4191d24", brd: "#33ffffff", rad: 20 }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        property bool active: HibikiState.uiTheme === modelData.id
                        Layout.fillWidth: true
                        height: 76
                        radius: modelData.rad
                        color: modelData.bg
                        border.width: active ? 2 : 1
                        border.color: active ? HibikiState.accentColor : modelData.brd
                        scale: tMa.pressed ? 0.95 : (active ? 1.03 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

                        Rectangle {
                            anchors.fill: parent; radius: parent.radius
                            visible: modelData.id !== "m3"
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: modelData.id === "liquid" ? "#55ffffff" : "#28ffffff" }
                                GradientStop { position: 0.5; color: "transparent" }
                            }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 3
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.title
                                color: active ? HibikiState.accentColor : "#ffffff"
                                font.pixelSize: 13; font.bold: true
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.sub
                                color: "#a8bacd"
                                font.pixelSize: 10
                            }
                        }

                        MouseArea {
                            id: tMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: HibikiState.setUiTheme(modelData.id)
                        }
                    }
                }
            }
        }

        Text { text: "Прозрачность стекла"; color: HibikiState.accentColor; font.pixelSize: 13; font.bold: true }
        BlockCard {
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Плотность ледяного фона"; color: "#ffffff"; font.pixelSize: 13 }
                Item { Layout.fillWidth: true }
                ChipBar { opts: ["55%", "68%", "82%", "92%"]; vals: ["8c", "ad", "d1", "eb"]; cur: HibikiState.glassAlpha; onPicked: function(v) { HibikiState.glassAlpha = v; HibikiState.saveState() } }
            }
        }

        Text { text: "Режим «Хамелеон»"; color: HibikiState.accentColor; font.pixelSize: 13; font.bold: true; Layout.topMargin: 4 }
        BlockCard {
            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    spacing: 2
                    Text { text: "Синхронизация с обоями (awww)"; color: "#ffffff"; font.pixelSize: 13; font.bold: true }
                    Text { text: "Автоматически подбирает акцент под текущие обои"; color: "#90a4b8"; font.pixelSize: 11 }
                }
                Item { Layout.fillWidth: true }
                TogglePill {
                    on: HibikiState.paletteMode === "chameleon"
                    onSwitched: function(v) { if (v) HibikiState.enableChameleon(true); else HibikiState.selectPreset(HibikiState.presetId); }
                }
            }
        }

        Text { text: "Заготовки цветовых палитр"; color: HibikiState.accentColor; font.pixelSize: 13; font.bold: true; Layout.topMargin: 4 }
        BlockCard {
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Выбор пресета"; color: "#d6e2ee"; font.pixelSize: 12 }
                Item { Layout.fillWidth: true }
                Row {
                    spacing: 10
                    Repeater {
                        model: HibikiState.palettePresets
                        delegate: Rectangle {
                            required property var modelData
                            property bool sel: HibikiState.paletteMode === "preset" && HibikiState.presetId === modelData.id
                            width: 30; height: 30; radius: 15
                            border.width: sel ? 2.5 : 1; border.color: sel ? "#ffffff" : "#55ffffff"
                            scale: sel ? 1.14 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: modelData.c1 }
                                GradientStop { position: 1.0; color: modelData.c2 }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: HibikiState.selectPreset(modelData.id) }
                        }
                    }
                }
            }
        }

        Text { text: "Композитор Niri • Геометрия окон"; color: HibikiState.accentColor; font.pixelSize: 13; font.bold: true; Layout.topMargin: 4 }
        BlockCard {
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Отступы между окнами (Gaps)"; color: "#ffffff"; font.pixelSize: 13 }
                Item { Layout.fillWidth: true }
                ChipBar { opts: ["4 px", "8 px", "10 px", "14 px", "18 px"]; vals: [4, 8, 10, 14, 18]; cur: HibikiState.niriGaps; onPicked: function(v) { HibikiState.niriGaps = v; HibikiState.saveState(); HibikiState.applyNiriConfig() } }
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Скругление углов окон"; color: "#d6e2ee"; font.pixelSize: 12 }
                Item { Layout.fillWidth: true }
                ChipBar { opts: ["8 px", "12 px", "16 px", "22 px"]; vals: [8, 12, 16, 22]; cur: HibikiState.niriCornerRadius; onPicked: function(v) { HibikiState.niriCornerRadius = v; HibikiState.saveState(); HibikiState.applyNiriConfig() } }
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Ледяная рамка активного окна"; color: "#d6e2ee"; font.pixelSize: 12 }
                Item { Layout.fillWidth: true }
                ChipBar { opts: ["1 px", "2 px", "3 px", "4 px"]; vals: [1, 2, 3, 4]; cur: HibikiState.niriFocusWidth; onPicked: function(v) { HibikiState.niriFocusWidth = v; HibikiState.saveState(); HibikiState.applyNiriConfig() } }
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Центрирование колонки"; color: "#d6e2ee"; font.pixelSize: 12 }
                Item { Layout.fillWidth: true }
                ChipBar { opts: ["Никогда", "Всегда", "Если одно"]; vals: ["never", "always", "on-overflow"]; cur: HibikiState.niriCenterCol; onPicked: function(v) { HibikiState.niriCenterCol = v; HibikiState.saveState(); HibikiState.applyNiriConfig() } }
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Мягкие тени под окнами"; color: "#d6e2ee"; font.pixelSize: 12 }
                Item { Layout.fillWidth: true }
                TogglePill { on: HibikiState.niriShadow; onSwitched: function(v) { HibikiState.niriShadow = v; HibikiState.saveState(); HibikiState.applyNiriConfig() } }
            }
        }
    }
}
