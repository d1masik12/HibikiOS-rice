import QtQuick
import QtQuick.Layouts

GridLayout {
    id: root
    columns: 2
    rowSpacing: 12
    columnSpacing: 12

    Repeater {
        model: ListModel {
            ListElement { title: "Процессор (CPU)"; kind: "cpu" }
            ListElement { title: "Видеокарта (GPU)"; kind: "gpu" }
            ListElement { title: "Память (RAM)"; kind: "ram" }
            ListElement { title: "Накопитель (SSD)"; kind: "disk" }
        }
        delegate: Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true; radius: 16
            color: HibikiState.cardColor; border.width: HibikiState.uiTheme === "m3" ? 0 : 1; border.color: "#26ffffff"
            property var st: HibikiState.stats || ({})
            property real animPct: kind === "cpu" ? (st.cpu || 0) : kind === "gpu" ? (st.gpu || 0) : kind === "ram" ? (st.ram || 0) : (st.diskPct || 0)
            Behavior on animPct { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
            onAnimPctChanged: ringCvs.requestPaint()
            property string subText: kind === "cpu" ? ((st.cpuTemp ? st.cpuTemp + " °C  •  " : "") + "i5-13500") :
                                     kind === "gpu" ? ((st.gpuTemp ? st.gpuTemp + " °C  •  " : "") + (Math.round((st.vramUsedMb || 0) / 1024 * 10) / 10) + " ГБ VRAM") :
                                     kind === "ram" ? ((st.ramUsedGb || 0) + " / " + (st.ramTotalGb || 64) + " ГБ") :
                                                      ((st.diskUsedGb || 0) + " / " + (st.diskTotalGb || 0) + " ГБ")
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 12; spacing: 6
                Text { Layout.alignment: Qt.AlignHCenter; text: title; color: "#f2f6fa"; font.pixelSize: 13; font.bold: true }
                Item {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    Canvas {
                        id: ringCvs; width: Math.min(parent.width, parent.height); height: width; anchors.centerIn: parent
                        onPaint: {
                            var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                            var cx = width / 2; var cy = height / 2; var r = Math.max(10, cx - 10)
                            ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.lineWidth = 8; ctx.strokeStyle = "#22ffffff"; ctx.stroke()
                            if (animPct > 0.5) {
                                ctx.beginPath(); ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.min(100, animPct) / 100.0)
                                ctx.lineWidth = 8; ctx.lineCap = "round"; ctx.strokeStyle = animPct >= 85 ? "#ff6b8b" : HibikiState.accentColor; ctx.stroke()
                            }
                        }
                    }
                    Text { anchors.centerIn: parent; text: Math.round(animPct) + "%"; color: "#ffffff"; font.pixelSize: 19; font.bold: true }
                }
                Text { Layout.alignment: Qt.AlignHCenter; text: subText; color: "#9aa8b8"; font.pixelSize: 11 }
            }
        }
    }
}
