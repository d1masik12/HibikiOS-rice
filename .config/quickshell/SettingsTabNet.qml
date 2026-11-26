import QtQuick
import QtQuick.Layouts

Flickable {
    id: rootTab
    required property var netData
    required property bool netBusy
    property string passSsid: ""
    signal refresh()
    signal action(var args)

    contentHeight: col.implicitHeight
    clip: true

    ColumnLayout {
        id: col; width: parent.width; spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Беспроводная сеть (Wi-Fi)"; color: HibikiState.accentColor; font.pixelSize: 13; font.bold: true }
            Item { Layout.fillWidth: true }
            Rectangle {
                height: 24; width: wRefLbl.implicitWidth + 16; radius: 8
                color: wRefMa.containsMouse ? "#2cffffff" : "#16ffffff"; border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: "#33ffffff"
                Text { id: wRefLbl; anchors.centerIn: parent; text: rootTab.netBusy ? "..." : "↻ Скан"; color: "#b8dce4"; font.pixelSize: 11 }
                MouseArea { id: wRefMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: rootTab.refresh() }
            }
        }
        Rectangle {
            Layout.fillWidth: true; implicitHeight: wCol.implicitHeight + 24; radius: 18; color: HibikiState.cardColor; border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: "#33ffffff"
            ColumnLayout {
                id: wCol; anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 } spacing: 8
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Адаптер Wi-Fi"; color: "#ffffff"; font.pixelSize: 13; font.bold: true }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        height: 26; width: 64; radius: 13; color: rootTab.netData.wifiOn ? "#55a6e3e9" : "#22ffffff"; border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: "#88a6e3e9"
                        Text { anchors.centerIn: parent; text: rootTab.netData.wifiOn ? "ВКЛ" : "ВЫКЛ"; color: "#ffffff"; font.pixelSize: 11; font.bold: true }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: rootTab.action(["wifi-toggle"]) }
                    }
                }
                RowLayout {
                    visible: rootTab.passSsid !== ""; Layout.fillWidth: true; spacing: 8
                    Rectangle {
                        Layout.fillWidth: true; height: 32; radius: 10; color: "#220e131a"; border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: "#66a6e3e9"
                        TextInput {
                            id: passIn; anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 12; echoMode: TextInput.Password
                            Keys.onReturnPressed: { rootTab.action(["wifi-connect", rootTab.passSsid, text]); text = ""; rootTab.passSsid = "" }
                        }
                    }
                    Rectangle {
                        height: 32; width: 80; radius: 10; color: "#44a6e3e9"; border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: "#cca6e3e9"
                        Text { anchors.centerIn: parent; text: "Войти"; color: "#ffffff"; font.pixelSize: 12; font.bold: true }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { rootTab.action(["wifi-connect", rootTab.passSsid, passIn.text]); passIn.text = ""; rootTab.passSsid = "" } }
                    }
                }
                Repeater {
                    model: rootTab.netData.wifiOn ? (rootTab.netData.nets || []) : []
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true; height: 34; radius: 10
                        color: modelData.active ? "#2ca6e3e9" : "#10ffffff"; border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: modelData.active ? "#88a6e3e9" : "#22ffffff"
                        RowLayout {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            Text { text: (modelData.secure ? "   " : "   ") + modelData.ssid; font.family: "Symbols Nerd Font"; color: "#ffffff"; font.pixelSize: 12 }
                            Item { Layout.fillWidth: true }
                            Text { text: modelData.active ? "Подключено" : (modelData.signal + "%"); color: HibikiState.accentColor; font.pixelSize: 11 }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.active) rootTab.action(["wifi-forget", modelData.ssid])
                                else if (modelData.secure) { rootTab.passSsid = modelData.ssid; passIn.forceActiveFocus() }
                                else rootTab.action(["wifi-connect", modelData.ssid])
                            }
                        }
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true; Layout.topMargin: 4
            Text { text: "Bluetooth устройства"; color: HibikiState.accentColor; font.pixelSize: 13; font.bold: true }
            Item { Layout.fillWidth: true }
            Rectangle {
                height: 24; width: bRefLbl.implicitWidth + 16; radius: 8
                color: bRefMa.containsMouse ? "#2cffffff" : "#16ffffff"; border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: "#33ffffff"
                Text { id: bRefLbl; anchors.centerIn: parent; text: "↻ Поиск"; color: "#b8dce4"; font.pixelSize: 11 }
                MouseArea { id: bRefMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: rootTab.action(["bt-scan"]) }
            }
        }
        Rectangle {
            Layout.fillWidth: true; implicitHeight: bCol.implicitHeight + 24; radius: 18; color: HibikiState.cardColor; border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: "#33ffffff"
            ColumnLayout {
                id: bCol; anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 } spacing: 8
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Питание Bluetooth"; color: "#ffffff"; font.pixelSize: 13; font.bold: true }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        height: 26; width: 64; radius: 13; color: rootTab.netData.btOn ? "#55a6e3e9" : "#22ffffff"; border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: "#88a6e3e9"
                        Text { anchors.centerIn: parent; text: rootTab.netData.btOn ? "ВКЛ" : "ВЫКЛ"; color: "#ffffff"; font.pixelSize: 11; font.bold: true }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: rootTab.action(["bt-toggle"]) }
                    }
                }
                Repeater {
                    model: rootTab.netData.btOn ? (rootTab.netData.devs || []) : []
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true; height: 34; radius: 10
                        color: modelData.connected ? "#2ca6e3e9" : "#10ffffff"; border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: modelData.connected ? "#88a6e3e9" : "#22ffffff"
                        RowLayout {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            Text { text: "   " + modelData.name; font.family: "Symbols Nerd Font"; color: "#ffffff"; font.pixelSize: 12 }
                            Item { Layout.fillWidth: true }
                            Text { text: modelData.connected ? "Отключить" : "Подключить"; color: HibikiState.accentColor; font.pixelSize: 11 }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: rootTab.action(["bt-conn", modelData.mac, modelData.connected ? "disconnect" : "connect"]) }
                    }
                }
            }
        }
    }
}
