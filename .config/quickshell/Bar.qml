import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Hibiki UI — three independent glass islands, one bar per output.
ShellRoot {
    Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
        id: bar
        required property var modelData
        screen: modelData
        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: 42
        color: "transparent"
        exclusiveZone: 42

        property string home: Quickshell.env("HOME")
        property var state: ({
            workspaces: [], focusedWindow: "",
            time: "--:--", date: "---, -- ---",
            layout: "EN", volume: 0, muted: false, micMuted: false,
            cpu: 0, gpu: 0, ram: 0, cpuTemp: null, gpuTemp: null,
            notifications: 0
        })
        property string outputName: screen ? screen.name : ""

        // Keyboard layout state, filled from niri events.
        property var kbNames: []
        property int kbIdx: -1

        function kbLabel(name) {
            var n = (name || "").toLowerCase()
            if (n.indexOf("russian") >= 0 || n.indexOf("рус") >= 0) return "RU"
            if (n.indexOf("english") >= 0) return "EN"
            return (name || "--").substring(0, 2).toUpperCase()
        }

        function layoutLabel() {
            if (kbNames.length > 0 && kbIdx >= 0 && kbIdx < kbNames.length)
                return kbLabel(kbNames[kbIdx])
            return state.layout || "EN"
        }

        function refreshState(raw) {
            try {
                var v = JSON.parse(raw)
                state = v
            } catch (e) {
                // Keep the last good snapshot if a command temporarily fails.
            }
        }

        function run(command) {
            actionProc.command = command
            actionProc.running = false
            actionProc.running = true
        }

        Process {
            id: pollProc
            command: ["/usr/bin/env", "python3", bar.home + "/.config/quickshell/poll.sh"]
            stdout: StdioCollector {
                id: pollCollector
                onStreamFinished: bar.refreshState(text)
            }
        }
        Process { id: actionProc; command: []; running: false }

        Timer {
            interval: 1200
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                pollProc.running = false
                pollProc.running = true
            }
        }


        Item {
            anchors.fill: parent

            // LEFT — monitor-local Niri workspaces and active window title.
            GlassIsland {
                id: leftIsland
                x: 12
                y: 5
                height: 32
                width: leftContent.implicitWidth + 22

                Row {
                    id: leftContent
                    anchors.centerIn: parent
                    spacing: 10

                    Row {
                        id: workspaceRow
                        spacing: 5
                        ListModel { id: wsModel }
                        Process {
                            id: niriStream
                            command: ["niri", "msg", "-j", "event-stream"]
                            running: true
                            stdout: SplitParser {
                                splitMarker: "\n"
                                onRead: function(line) {
                                    if (!line || line.trim().length === 0) return
                                    try {
                                        var ev = JSON.parse(line)
                                        if (ev.WorkspacesChanged) {
                                            var list = ev.WorkspacesChanged.workspaces.filter(function(w) { return w.output === bar.outputName })
                                            list.sort(function(a, b) { return a.idx - b.idx })
                                            if (wsModel.count !== list.length) {
                                                wsModel.clear()
                                                for (var i = 0; i < list.length; ++i) {
                                                    wsModel.append({ wsId: list[i].id, idx: list[i].idx, wsName: list[i].name || "", focused: !!list[i].is_focused, active: !!list[i].is_active })
                                                }
                                            } else {
                                                for (var j = 0; j < list.length; ++j) {
                                                    wsModel.setProperty(j, "wsId", list[j].id)
                                                    wsModel.setProperty(j, "idx", list[j].idx)
                                                    wsModel.setProperty(j, "focused", !!list[j].is_focused)
                                                    wsModel.setProperty(j, "active", !!list[j].is_active)
                                                }
                                            }
                                        } else if (ev.WorkspaceActivated) {
                                            var id = ev.WorkspaceActivated.id
                                            var foc = !!ev.WorkspaceActivated.focused
                                            var found = false
                                            for (var k = 0; k < wsModel.count; ++k) {
                                                if (wsModel.get(k).wsId === id) found = true
                                            }
                                            if (found) {
                                                for (var m = 0; m < wsModel.count; ++m) {
                                                    var isTarget = (wsModel.get(m).wsId === id)
                                                    wsModel.setProperty(m, "active", isTarget)
                                                    if (isTarget || foc) wsModel.setProperty(m, "focused", isTarget && foc)
                                                }
                                            }
                                        } else if (ev.KeyboardLayoutsChanged) {
                                            var kl = ev.KeyboardLayoutsChanged.keyboard_layouts
                                            bar.kbNames = kl.names || []
                                            bar.kbIdx = kl.current_idx !== undefined ? kl.current_idx : 0
                                        } else if (ev.KeyboardLayoutSwitched) {
                                            bar.kbIdx = ev.KeyboardLayoutSwitched.idx
                                        }
                                    } catch (e) {}
                                }
                            }
                        }
                        Repeater {
                            model: wsModel
                            delegate: Item {
                                width: model.focused ? 23 : (model.active ? 14 : 9)
                                height: 20
                                Behavior on width { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width
                                    height: 6
                                    radius: 3
                                    color: model.focused ? "#a6e3e9" : (model.active ? "#a0e2eefc" : "#667b8798")
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: bar.run(["niri", "msg", "action", "focus-workspace", String(model.wsName || model.idx)])
                                    onWheel: function(wheel) {
                                        if (wheel.angleDelta.y > 0)
                                            bar.run(["niri", "msg", "action", "focus-workspace-up"])
                                        else if (wheel.angleDelta.y < 0)
                                            bar.run(["niri", "msg", "action", "focus-workspace-down"])
                                    }
                                }
                            }
                        }
                    }

                    Rectangle { width: 1; height: 15; color: "#35e2eefc"; opacity: 0.65 }

                    Text {
                        width: Math.min(230, implicitWidth)
                        text: bar.state.focusedWindow || "Desktop"
                        color: "#e2eefc"
                        font.pixelSize: 11
                        font.family: "sans-serif"
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            // CENTER — clock/date with distinct left/right mouse actions.
            GlassIsland {
                id: clockIsland
                anchors.horizontalCenter: parent.horizontalCenter
                y: 5
                height: 32
                width: clockText.implicitWidth + 24
                hovered: clockMa.containsMouse
                pressed: clockMa.pressed
                Text {
                    id: clockText
                    anchors.centerIn: parent
                    text: (bar.state.time || "--:--") + "  ·  " + (bar.state.date || "---, -- ---")
                    color: "#e2eefc"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }
                MouseArea {
                    id: clockMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.LeftButton)
                            HibikiState.controlOpen = !HibikiState.controlOpen
                        else if (mouse.button === Qt.RightButton)
                            bar.run([bar.home + "/.local/bin/wall-carousel"])
                    }
                }
            }

            // RIGHT — compact separate lenses.
            Row {
                id: rightGroup
                anchors.right: parent.right
                anchors.rightMargin: 12
                y: 5
                height: 32
                spacing: 6

                // Keyboard layout
                GlassIsland {
                    customRadius: 11
                    width: layoutText.implicitWidth + 20
                    height: 32
                    hovered: layMa.containsMouse
                    pressed: layMa.pressed
                    Text {
                        id: layoutText
                        anchors.centerIn: parent
                        text: bar.layoutLabel()
                        color: "#a6e3e9"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        id: layMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bar.run(["niri", "msg", "action", "switch-layout", "next"])
                    }
                }

                // Wi-Fi (visual only for now)
                GlassIsland {
                    customRadius: 11
                    width: 34
                    height: 32
                    hovered: wifiMa.containsMouse
                    Text {
                        anchors.centerIn: parent
                        text: "󰖩"
                        color: "#e2eefc"
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 13
                    }
                    MouseArea {
                        id: wifiMa
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }

                // Audio
                GlassIsland {
                    customRadius: 11
                    width: audioRow.implicitWidth + 20
                    height: 32
                    hovered: audioMa.containsMouse
                    pressed: audioMa.pressed
                    Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    Row {
                        id: audioRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            id: audioIcon
                            anchors.verticalCenter: parent.verticalCenter
                            text: bar.state.muted ? "󰖁" : ((bar.state.volume || 0) >= 50 ? "󰕾" : "󰖀")
                            color: bar.state.muted ? "#f38ba8" : "#a6e3e9"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 13
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: (bar.state.volume || 0) + "%"
                            color: bar.state.muted ? "#f38ba8" : "#e2eefc"
                            font.family: "Inter"
                            font.pixelSize: 11
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !!bar.state.micMuted
                            text: "󰍭"
                            color: "#f38ba8"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 11
                        }
                    }
                    MouseArea {
                        id: audioMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.LeftButton) {
                                if (audioIcon.contains(audioIcon.mapFromItem(audioMa, mouse.x, mouse.y)))
                                    HibikiState.audioOpen = !HibikiState.audioOpen
                                else {
                                    bar.state = Object.assign({}, bar.state, { muted: !bar.state.muted })
                                    bar.run(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"])
                                }
                            }
                            else if (mouse.button === Qt.MiddleButton) {
                                bar.state = Object.assign({}, bar.state, { micMuted: !bar.state.micMuted })
                                bar.run(["pactl", "set-source-mute", "@DEFAULT_SOURCE@", "toggle"])
                            }
                            else if (mouse.button === Qt.RightButton)
                                bar.run(["pavucontrol"])
                        }
                        onWheel: function(wheel) {
                            var step = wheel.angleDelta.y > 0 ? "+5%" : "-5%"
                            var nv = Math.max(0, Math.min(150, (bar.state.volume || 0) + (wheel.angleDelta.y > 0 ? 5 : -5)))
                            bar.state = Object.assign({}, bar.state, { volume: nv })
                            bar.run(["pactl", "set-sink-volume", "@DEFAULT_SINK@", step])
                        }
                    }
                }

                // Monitoring (no hover temps)
                GlassIsland {
                    id: sensorIsland
                    customRadius: 11
                    width: sensorRow.implicitWidth + 20
                    height: 32
                    clip: true
                    hovered: sensorHover.containsMouse
                    Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    Row {
                        id: sensorRow
                        anchors.centerIn: parent
                        spacing: 8
                        Text { text: "CPU " + bar.state.cpu + "%"; color: "#e2eefc"; font.pixelSize: 10 }
                        Text { text: "GPU " + bar.state.gpu + "%"; color: "#a6e3e9"; font.pixelSize: 10 }
                        Text { text: "RAM " + bar.state.ram + "%"; color: "#e2eefc"; font.pixelSize: 10 }
                    }
                    MouseArea {
                        id: sensorHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }

                // Notifications
                GlassIsland {
                    customRadius: 11
                    width: 34
                    height: 32
                    hovered: notifyMa.containsMouse
                    pressed: notifyMa.pressed
                    Item {
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        Text {
                            anchors.centerIn: parent
                            text: "󰂚"
                            color: "#e2eefc"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 13
                        }
                        Rectangle {
                            visible: (bar.state.notifications || 0) > 0
                            width: 6
                            height: 6
                            radius: 3
                            color: "#f38ba8"
                            anchors.top: parent.top
                            anchors.right: parent.right
                        }
                    }
                    MouseArea {
                        id: notifyMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.LeftButton)
                                { HibikiState.controlOpen = false; HibikiState.notifOpen = !HibikiState.notifOpen }
                            else if (mouse.button === Qt.RightButton)
                                { HibikiState.dndEnabled = !HibikiState.dndEnabled; HibikiState.saveState() }
                        }
                    }
                }
            }
        }
    }


    }

    ControlCenter {}
    CavaVisualizer {}
    NotificationCenter {}
}
