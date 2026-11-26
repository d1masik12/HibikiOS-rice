import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

Scope {
    id: root

    property string query: ""
    property int selectedIndex: 0

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            HibikiState.controlOpen = false
            HibikiState.notifOpen = false
            HibikiState.settingsOpen = false
            HibikiState.activePopover = ""
            HibikiState.launcherOpen = !HibikiState.launcherOpen
        }
        function open(): void {
            HibikiState.controlOpen = false
            HibikiState.notifOpen = false
            HibikiState.settingsOpen = false
            HibikiState.activePopover = ""
            HibikiState.launcherOpen = true
        }
        function close(): void { HibikiState.launcherOpen = false }
    }

    property var filteredApps: {
        var all = DesktopEntries.applications.values
        var q = root.query.trim().toLowerCase()
        var res = []
        for (var i = 0; i < all.length; i++) {
            var app = all[i]
            if (!app || app.noDisplay) continue
            var name = (app.name || "").toLowerCase()
            var generic = (app.genericName || "").toLowerCase()
            var comment = (app.comment || "").toLowerCase()
            if (q === "" || name.indexOf(q) >= 0 || generic.indexOf(q) >= 0 || comment.indexOf(q) >= 0) {
                res.push(app)
            }
        }
        res.sort(function(a, b) {
            var an = (a.name || "").toLowerCase()
            var bn = (b.name || "").toLowerCase()
            if (q !== "") {
                var aStarts = an.indexOf(q) === 0
                var bStarts = bn.indexOf(q) === 0
                if (aStarts !== bStarts) return aStarts ? -1 : 1
            }
            return an.localeCompare(bn)
        })
        return res
    }

    function launchApp(app) {
        if (!app) return
        app.execute()
        HibikiState.launcherOpen = false
    }

    property var targetScreen: {
        var list = Quickshell.screens
        var want = HibikiState.uiScreen === "all" ? HibikiState.activeOutput : HibikiState.uiScreen
        for (var i = 0; i < list.length; i++) if (list[i].name === want) return list[i]
        return list.length > 0 ? list : null
    }
    PanelWindow {
        id: win
        screen: root.targetScreen
        visible: HibikiState.launcherOpen || anim > 0.01
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: HibikiState.launcherOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        property real anim: HibikiState.launcherOpen ? 1.0 : 0.0
        Behavior on anim {
            NumberAnimation {
                duration: HibikiState.launcherOpen ? 280 : 190
                easing.type: HibikiState.launcherOpen ? Easing.OutBack : Easing.InCubic
                easing.overshoot: 1.1
            }
        }

        onVisibleChanged: {
            if (visible && HibikiState.launcherOpen) {
                root.query = ""
                root.selectedIndex = 0
                searchInput.text = ""
                searchInput.forceActiveFocus()
            }
        }

        MouseArea { anchors.fill: parent; onClicked: HibikiState.launcherOpen = false }

        Rectangle {
            id: panel
            width: 540; height: 520
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 10 - (1.0 - win.anim) * 18
            opacity: Math.min(1.0, win.anim * 1.4)
            scale: 0.90 + 0.10 * win.anim
            radius: HibikiState.panelRadius
            color: HibikiState.glassColor
            border.width: HibikiState.panelBorderWidth
            border.color: HibikiState.panelBorderColor
            clip: true

            Rectangle {
                anchors.fill: parent; radius: parent.radius
                visible: HibikiState.uiTheme !== "m3"
                gradient: Gradient {
                    GradientStop { position: 0.0; color: HibikiState.specularTop }
                    GradientStop { position: 0.25; color: HibikiState.specularMid }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 18; spacing: 12

                // Поле поиска
                Rectangle {
                    Layout.fillWidth: true; height: 46
                    radius: HibikiState.cardRadius
                    color: HibikiState.cardColor
                    border.width: HibikiState.uiTheme === "m3" ? 0 : 1
                    border.color: Qt.alpha(HibikiState.accentColor, 0.55)

                    RowLayout {
                        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                        spacing: 10
                        Text {
                            text: "  "
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 17
                            color: HibikiState.accentColor
                        }
                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            color: "#ffffff"
                            font.pixelSize: 14
                            clip: true
                            onTextChanged: {
                                root.query = text
                                root.selectedIndex = 0
                                appList.positionViewAtBeginning()
                            }
                            Keys.onEscapePressed: HibikiState.launcherOpen = false
                            Keys.onReturnPressed: {
                                if (root.filteredApps.length > 0) root.launchApp(root.filteredApps[root.selectedIndex])
                            }
                            Keys.onDownPressed: {
                                if (root.filteredApps.length > 0) {
                                    root.selectedIndex = (root.selectedIndex + 1) % root.filteredApps.length
                                    appList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                                }
                            }
                            Keys.onUpPressed: {
                                if (root.filteredApps.length > 0) {
                                    root.selectedIndex = (root.selectedIndex - 1 + root.filteredApps.length) % root.filteredApps.length
                                    appList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                                }
                            }
                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Поиск приложений..."
                                color: "#7f93a8"
                                font.pixelSize: 14
                                visible: searchInput.text.length === 0
                            }
                        }
                        Text {
                            text: root.filteredApps.length + ""
                            color: "#8fa3b8"
                            font.pixelSize: 11
                        }
                    }
                }

                // Список приложений
                ListView {
                    id: appList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 6
                    model: root.filteredApps

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        property bool sel: index === root.selectedIndex
                        width: appList.width
                        height: 50
                        radius: HibikiState.uiTheme === "m3" ? 16 : 13
                        color: sel ? Qt.alpha(HibikiState.accentColor, HibikiState.uiTheme === "m3" ? 0.28 : 0.22) : (rowMa.containsMouse ? "#1affffff" : "transparent")
                        border.width: (sel && HibikiState.uiTheme !== "m3") ? 1 : 0
                        border.color: Qt.alpha(HibikiState.accentColor, 0.65)
                        Behavior on color { ColorAnimation { duration: 130 } }

                        RowLayout {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 14 }
                            spacing: 12

                            Image {
                                width: 30; height: 30
                                sourceSize.width: 30; sourceSize.height: 30
                                source: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
                                smooth: true
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name || "App"
                                    color: sel ? "#ffffff" : "#e2ecf7"
                                    font.pixelSize: 13
                                    font.bold: sel
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    visible: text.length > 0
                                    text: modelData.genericName || modelData.comment || ""
                                    color: sel ? "#c6dce8" : "#889cb0"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                visible: sel
                                text: "↵"
                                color: HibikiState.accentColor
                                font.pixelSize: 14
                                font.bold: true
                            }
                        }

                        MouseArea {
                            id: rowMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.selectedIndex = index
                            onClicked: root.launchApp(modelData)
                        }
                    }
                }
            }
        }
    }
}
