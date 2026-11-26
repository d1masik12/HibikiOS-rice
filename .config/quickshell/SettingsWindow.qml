import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

Scope {
    id: root
    property var netData: ({ wifiOn: true, nets: [], btOn: false, devs: [] })
    property string wifiPassSsid: ""
    property bool netBusy: false

    function refreshNet() {
        netReadProc.running = false
        netReadProc.running = true
    }
    function runNetAct(args) {
        root.netBusy = true
        netActProc.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/net_bt.py"].concat(args)
        netActProc.running = false
        netActProc.running = true
    }

    Process {
        id: netReadProc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/net_bt.py"]
        stdout: SplitParser {
            onRead: function(line) {
                try { root.netData = JSON.parse(line) } catch (e) {}
                root.netBusy = false
            }
        }
    }
    Process {
        id: netActProc
        onExited: root.refreshNet()
    }

    IpcHandler {
        target: "settings"
        function toggle(): void {
            HibikiState.controlOpen = false
            HibikiState.notifOpen = false
            HibikiState.activePopover = ""
            HibikiState.settingsOpen = !HibikiState.settingsOpen
        }
        function open(): void {
            HibikiState.controlOpen = false
            HibikiState.notifOpen = false
            HibikiState.activePopover = ""
            HibikiState.settingsOpen = true
        }
        function close(): void { HibikiState.settingsOpen = false }
    }

    property var mainScreen: {
        var list = Quickshell.screens
        for (var i = 0; i < list.length; i++) if (list[i].name === (HibikiState.uiScreen === "all" ? HibikiState.activeOutput : HibikiState.uiScreen)) return list[i]
        return list.length > 0 ? list[0] : null
    }

    component IceCard: Rectangle {
        default property alias content: col.data
        Layout.fillWidth: true
        implicitHeight: col.implicitHeight + 24
        radius: 18; color: HibikiState.cardColor; border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: "#33ffffff"
        ColumnLayout { id: col; anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 } spacing: 10 }
    }

    component IceSwitch: Rectangle {
        id: sw
        property bool checked: false
        signal toggled(bool val)
        width: 46; height: 26; radius: 13
        color: checked ? "#55a6e3e9" : "#22ffffff"
        border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: checked ? HibikiState.accentColor : "#44ffffff"
        Behavior on color { ColorAnimation { duration: 180 } }
        Rectangle {
            width: 18; height: 18; radius: 9; y: 3
            x: sw.checked ? parent.width - width - 4 : 4
            color: sw.checked ? HibikiState.accentColor : "#b8c7d9"
            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }
            Behavior on color { ColorAnimation { duration: 180 } }
        }
        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sw.toggled(!sw.checked) }
    }

    component IceChips: Row {
        id: chRow
        property var options: []
        property var values: []
        property var currentValue
        signal selected(var val)
        spacing: 6
        Repeater {
            model: chRow.options.length
            delegate: Rectangle {
                required property int index
                property bool active: chRow.values[index] === chRow.currentValue
                height: 28; width: lbl.implicitWidth + 20; radius: 10
                color: active ? "#44a6e3e9" : (cMa.containsMouse ? "#26ffffff" : "#16ffffff")
                border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: active ? HibikiState.accentColor : "#33ffffff"
                scale: cMa.pressed ? 0.94 : 1.0
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 100 } }
                Text { id: lbl; anchors.centerIn: parent; text: chRow.options[index]; color: active ? "#ffffff" : "#b8c8d8"; font.pixelSize: 12; font.bold: active }
                MouseArea { id: cMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: chRow.selected(chRow.values[index]) }
            }
        }
    }
    PanelWindow {
        id: win
        screen: root.mainScreen
        visible: HibikiState.settingsOpen || dropAnim > 0.01
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: HibikiState.settingsOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        property real dropAnim: HibikiState.settingsOpen ? 1.0 : 0.0
        Behavior on dropAnim {
            NumberAnimation {
                duration: HibikiState.settingsOpen ? 340 : 220
                easing.type: HibikiState.settingsOpen ? Easing.OutBack : Easing.InCubic
                easing.overshoot: 1.12
            }
        }
        MouseArea { anchors.fill: parent; onClicked: HibikiState.settingsOpen = false }

        Rectangle {
            id: panel
            width: 780; height: 540
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 21
            opacity: Math.min(1.0, win.dropAnim * 1.35)
            scale: 0.86 + 0.14 * win.dropAnim
            radius: HibikiState.panelRadius; color: HibikiState.glassColor; border.width: HibikiState.panelBorderWidth; border.color: HibikiState.panelBorderColor; clip: true

            Rectangle {
                anchors.fill: parent; radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: HibikiState.specularTop }
                    GradientStop { position: 0.28; color: HibikiState.specularMid }
                    GradientStop { position: 1.0; color: "#04a6e3e9" }
                }
            }

            focus: true
            Keys.onEscapePressed: HibikiState.settingsOpen = false
            MouseArea { anchors.fill: parent }

            RowLayout {
                anchors.fill: parent; anchors.margins: 18; spacing: 16

                Rectangle {
                    Layout.preferredWidth: 215; Layout.fillHeight: true; radius: 20
                    color: "#12ffffff"; border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: "#2cffffff"

                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 12; spacing: 8
                        RowLayout {
                            Layout.fillWidth: true; Layout.bottomMargin: 8; spacing: 10
                            Rectangle {
                                width: 34; height: 34; radius: 11; color: "#28a6e3e9"; border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: "#66a6e3e9"
                                Text { anchors.centerIn: parent; text: "⚙"; color: HibikiState.accentColor; font.pixelSize: 17 }
                            }
                            ColumnLayout {
                                spacing: 1
                                Text { text: "Настройки"; color: "#ffffff"; font.pixelSize: 15; font.bold: true }
                                Text { text: "Hibiki UI • Niri"; color: "#8fa3b8"; font.pixelSize: 11 }
                            }
                        }

                        Repeater {
                            model: ListModel {
                                ListElement { idx: 0; icon: "  "; title: "Дисплеи и Ввод"; sub: "Мониторы, мышь, язык" }
                                ListElement { idx: 1; icon: "  "; title: "Система и Медиа"; sub: "Тосты, Cava, сервис" }
                                ListElement { idx: 2; icon: "  "; title: "Внешний вид"; sub: "Стекло, цвета, Niri" }
                                ListElement { idx: 3; icon: "  "; title: "Сети и связь"; sub: "Wi-Fi и Bluetooth" }
                            }
                            delegate: Rectangle {
                                required property int idx; required property string icon; required property string title; required property string sub
                                property bool active: HibikiState.settingsTab === idx
                                Layout.fillWidth: true; height: 54; radius: 14
                                color: active ? "#34a6e3e9" : (navMa.containsMouse ? "#1cffffff" : "transparent")
                                border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: active ? HibikiState.accentColor : "transparent"
                                Behavior on color { ColorAnimation { duration: 160 } }
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 10; spacing: 10
                                    Text { text: icon; font.family: "Symbols Nerd Font"; font.pixelSize: 16; color: active ? HibikiState.accentColor : "#9cb0c4" }
                                    ColumnLayout {
                                        spacing: 1
                                        Text { text: title; color: active ? "#ffffff" : "#d6e2ee"; font.pixelSize: 13; font.bold: active }
                                        Text { text: sub; color: active ? "#b6dce4" : "#7e92a6"; font.pixelSize: 10 }
                                    }
                                }
                                MouseArea { id: navMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { HibikiState.settingsTab = idx; if (idx === 3) root.refreshNet() } }
                            }
                        }
                        Item { Layout.fillHeight: true }
                        Rectangle {
                            Layout.fillWidth: true; height: 36; radius: 12
                            color: closeMa.containsMouse ? "#2cffffff" : "#16ffffff"; border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: "#33ffffff"
                            Text { anchors.centerIn: parent; text: "Закрыть (Esc)"; color: "#cfe0f0"; font.pixelSize: 12 }
                            MouseArea { id: closeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: HibikiState.settingsOpen = false }
                        }
                    }
                }
                Item {
                    Layout.fillWidth: true; Layout.fillHeight: true

                    Flickable {
                        anchors.fill: parent; visible: HibikiState.settingsTab === 0
                        contentHeight: tab0Col.implicitHeight; clip: true
                        ColumnLayout {
                            id: tab0Col; width: parent.width; spacing: 12
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Мониторы Niri (" + HibikiState.detectedOutputs.length + " шт.)"; color: HibikiState.accentColor; font.pixelSize: 13; font.bold: true }
                                Item { Layout.fillWidth: true }
                                Rectangle {
                                    height: 24; width: refLbl.implicitWidth + 16; radius: 8
                                    color: refMa.containsMouse ? "#2cffffff" : "#16ffffff"; border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: "#33ffffff"
                                    Text { id: refLbl; anchors.centerIn: parent; text: "↻ Обновить"; color: "#b8dce4"; font.pixelSize: 11 }
                                    MouseArea { id: refMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: HibikiState.refreshOutputs() }
                                }
                            }

                            Repeater {
                                model: HibikiState.detectedOutputs
                                delegate: IceCard {
                                    required property var modelData
                                    required property int index
                                    property string monName: modelData.name
                                    property var cfg: HibikiState.getMonCfg(monName)

                                    RowLayout {
                                        Layout.fillWidth: true
                                        ColumnLayout {
                                            spacing: 2
                                            Text { text: monName + (modelData.hz ? (" • " + modelData.hz) : ""); color: "#ffffff"; font.pixelSize: 13; font.bold: true }
                                            Text { text: modelData.desc; color: "#90a4b8"; font.pixelSize: 11 }
                                        }
                                        Item { Layout.fillWidth: true }
                                        IceSwitch {
                                            visible: HibikiState.detectedOutputs.length > 1
                                            checked: cfg.enabled !== false
                                            onToggled: function(v) { HibikiState.setMonProp(monName, "enabled", v) }
                                        }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Адаптивная синхронизация (VRR)"; color: "#d6e2ee"; font.pixelSize: 12 }
                                        Item { Layout.fillWidth: true }
                                        IceSwitch {
                                            checked: !!cfg.vrr
                                            onToggled: function(v) { HibikiState.setMonProp(monName, "vrr", v) }
                                        }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Масштаб (" + monName + ")"; color: "#d6e2ee"; font.pixelSize: 12 }
                                        Item { Layout.fillWidth: true }
                                        IceChips {
                                            options: ["100%", "125%", "150%"]
                                            values: [1.0, 1.25, 1.5]
                                            currentValue: cfg.scale || 1.0
                                            onSelected: function(v) { HibikiState.setMonProp(monName, "scale", v) }
                                        }
                                    }
                                }
                            }

                            Text {
                                visible: HibikiState.detectedOutputs.length > 1
                                text: "Мультимониторность Hibiki UI"
                                color: HibikiState.accentColor; font.pixelSize: 13; font.bold: true; Layout.topMargin: 4
                            }

                            IceCard {
                                visible: HibikiState.detectedOutputs.length > 1
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Центр управления (по фокусу)"; color: "#d6e2ee"; font.pixelSize: 12 }
                                    Item { Layout.fillWidth: true }
                                    IceChips {
                                        options: HibikiState.screenChoiceLabels()
                                        values: HibikiState.screenChoiceValues()
                                        currentValue: HibikiState.uiScreen
                                        onSelected: function(v) { HibikiState.uiScreen = v; HibikiState.saveState() }
                                    }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Уведомления и шторка"; color: "#d6e2ee"; font.pixelSize: 12 }
                                    Item { Layout.fillWidth: true }
                                    IceChips {
                                        options: HibikiState.screenChoiceLabels()
                                        values: HibikiState.screenChoiceValues()
                                        currentValue: HibikiState.notifScreen
                                        onSelected: function(v) { HibikiState.notifScreen = v; HibikiState.saveState() }
                                    }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Фоновый эквалайзер Cava"; color: "#d6e2ee"; font.pixelSize: 12 }
                                    Item { Layout.fillWidth: true }
                                    IceChips {
                                        options: HibikiState.screenChoiceLabels()
                                        values: HibikiState.screenChoiceValues()
                                        currentValue: HibikiState.cavaScreen
                                        onSelected: function(v) { HibikiState.cavaScreen = v; HibikiState.saveState() }
                                    }
                                }
                            }

                            Text { text: "Клавиатура и Мышь"; color: HibikiState.accentColor; font.pixelSize: 13; font.bold: true; Layout.topMargin: 4 }

                            IceCard {
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Переключение RU / EN"; color: "#ffffff"; font.pixelSize: 13 }
                                    Item { Layout.fillWidth: true }
                                    IceChips { options: ["Alt + Shift", "Win + Space", "Caps Lock"]; values: ["grp:alt_shift_toggle", "grp:win_space_toggle", "grp:caps_toggle"]; currentValue: HibikiState.xkbOptions; onSelected: function(v) { HibikiState.xkbOptions = v; HibikiState.saveState(); HibikiState.applyNiriConfig() } }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Запоминание раскладки"; color: "#d6e2ee"; font.pixelSize: 12 }
                                    Item { Layout.fillWidth: true }
                                    IceChips { options: ["Общая", "На окно"]; values: ["global", "window"]; currentValue: HibikiState.trackLayout; onSelected: function(v) { HibikiState.trackLayout = v; HibikiState.saveState(); HibikiState.applyNiriConfig() } }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Профиль мыши"; color: "#d6e2ee"; font.pixelSize: 12 }
                                    Item { Layout.fillWidth: true }
                                    IceChips { options: ["Flat", "Adaptive"]; values: ["flat", "adaptive"]; currentValue: HibikiState.mouseAccel; onSelected: function(v) { HibikiState.mouseAccel = v; HibikiState.saveState(); HibikiState.applyNiriConfig() } }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Скорость курсора"; color: "#d6e2ee"; font.pixelSize: 12 }
                                    Item { Layout.fillWidth: true }
                                    IceChips { options: ["-0.4", "-0.2", "0.0", "+0.2", "+0.4"]; values: [-0.4, -0.2, 0.0, 0.2, 0.4]; currentValue: HibikiState.mouseSpeed; onSelected: function(v) { HibikiState.mouseSpeed = v; HibikiState.saveState(); HibikiState.applyNiriConfig() } }
                                }
                            }
                        }
                    }
                    Flickable {
                        anchors.fill: parent; visible: HibikiState.settingsTab === 1
                        contentHeight: tab1Col.implicitHeight; clip: true
                        ColumnLayout {
                            id: tab1Col; width: parent.width; spacing: 12
                            Text { text: "Уведомления Hibiki UI"; color: HibikiState.accentColor; font.pixelSize: 13; font.bold: true }

                            IceCard {
                                RowLayout {
                                    Layout.fillWidth: true
                                    ColumnLayout {
                                        spacing: 2
                                        Text { text: "Режим «Не беспокоить»"; color: "#ffffff"; font.pixelSize: 13; font.bold: true }
                                        Text { text: "Скрывать всплывающие тосты на экране"; color: "#90a4b8"; font.pixelSize: 11 }
                                    }
                                    Item { Layout.fillWidth: true }
                                    IceSwitch { checked: HibikiState.dndEnabled; onToggled: function(v) { HibikiState.dndEnabled = v; HibikiState.saveState() } }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Длительность показа тостов"; color: "#d6e2ee"; font.pixelSize: 12 }
                                    Item { Layout.fillWidth: true }
                                    IceChips { options: ["3 сек", "5 сек", "8 сек", "10 сек"]; values: [3000, 5000, 8000, 10000]; currentValue: HibikiState.toastTimeout; onSelected: function(v) { HibikiState.toastTimeout = v; HibikiState.saveState() } }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Максимум тостов одновременно"; color: "#d6e2ee"; font.pixelSize: 12 }
                                    Item { Layout.fillWidth: true }
                                    IceChips { options: ["2", "3", "4", "5"]; values: [2, 3, 4, 5]; currentValue: HibikiState.maxPopups; onSelected: function(v) { HibikiState.maxPopups = v; HibikiState.saveState() } }
                                }
                            }

                            Text { text: "Аудио-визуализатор и Оболочка"; color: HibikiState.accentColor; font.pixelSize: 13; font.bold: true; Layout.topMargin: 4 }

                            IceCard {
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Фоновый эквалайзер Cava"; color: "#ffffff"; font.pixelSize: 13 }
                                    Item { Layout.fillWidth: true }
                                    IceSwitch { checked: HibikiState.cavaEnabled; onToggled: function(v) { HibikiState.cavaEnabled = v; HibikiState.saveState() } }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Стиль эквалайзера"; color: "#d6e2ee"; font.pixelSize: 12 }
                                    Item { Layout.fillWidth: true }
                                    IceChips { options: ["Bars", "Wave", "Mirror", "Ring"]; values: ["bars", "wave", "mirror", "ring"]; currentValue: HibikiState.cavaStyle; onSelected: function(v) { HibikiState.cavaStyle = v; HibikiState.saveState() } }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Синхронный текст песен"; color: "#d6e2ee"; font.pixelSize: 12 }
                                    Item { Layout.fillWidth: true }
                                    IceSwitch { checked: HibikiState.lyricsEnabled; onToggled: function(v) { HibikiState.lyricsEnabled = v; HibikiState.saveState() } }
                                }
                            }

                            IceCard {
                                Text { text: "Обслуживание системы"; color: "#ffffff"; font.pixelSize: 13; font.bold: true }
                                RowLayout {
                                    Layout.fillWidth: true; spacing: 8
                                    Rectangle {
                                        Layout.fillWidth: true; height: 34; radius: 11
                                        color: r1Ma.containsMouse ? "#34a6e3e9" : "#1cffffff"; border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: "#55a6e3e9"
                                        Text { anchors.centerIn: parent; text: "Перезагрузить Niri"; color: "#e6f5ff"; font.pixelSize: 12 }
                                        MouseArea { id: r1Ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: HibikiState.runCmd(["niri", "msg", "action", "load-config-file"]) }
                                    }
                                    Rectangle {
                                        Layout.fillWidth: true; height: 34; radius: 11
                                        color: r2Ma.containsMouse ? "#34a6e3e9" : "#1cffffff"; border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: "#55a6e3e9"
                                        Text { anchors.centerIn: parent; text: "Рестарт Quickshell"; color: "#e6f5ff"; font.pixelSize: 12 }
                                        MouseArea { id: r2Ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: HibikiState.runCmd(["sh", "-c", "pkill -9 quickshell; sleep 0.3; quickshell &"]) }
                                    }
                                }
                            }
                        }
                    }

                    SettingsTabLook { anchors.fill: parent; visible: HibikiState.settingsTab === 2 }
                    SettingsTabNet { anchors.fill: parent; visible: HibikiState.settingsTab === 3; netData: root.netData; netBusy: root.netBusy; onRefresh: root.refreshNet(); onAction: function(a) { root.runNetAct(a) } }
                }
            }
        }
    }
}
