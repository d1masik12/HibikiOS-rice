import QtQuick

Rectangle {
    id: root

    property bool hovered: false
    property bool pressed: false
    property real customRadius: height / 2
    // Интенсивность инея: 0 — выключен, 1 — полный
    property real frost: 0.6

    radius: customRadius
    color: hovered ? "#d6142232" : "#cc0e1620"
    border.width: 1
    border.color: hovered ? "#70a6e3e9" : "#2cbfe9f5"
    antialiasing: true
    scale: pressed ? 0.97 : 1.0
    clip: true

    Behavior on color { ColorAnimation { duration: 160 } }
    Behavior on border.color { ColorAnimation { duration: 160 } }
    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

    // Холодный блик сверху
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, parent.radius - 1)
        color: "transparent"
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.hovered ? "#40f0fbff" : "#2aef4ff" }
            GradientStop { position: 0.42; color: "#0ad8f4ff" }
            GradientStop { position: 1.0; color: "#00000000" }
        }
    }

    // Тонкая холодная линия по нижнему краю
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.radius
        anchors.rightMargin: root.radius
        anchors.bottomMargin: 1
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#00a6e3e9" }
            GradientStop { position: 0.5; color: root.hovered ? "#66d8f4ff" : "#33a6e3e9" }
            GradientStop { position: 1.0; color: "#00a6e3e9" }
        }
    }

    // Иней: ветвистые кристаллы от краёв, рисуются один раз на размер
    Canvas {
        id: frostCanvas
        anchors.fill: parent
        opacity: root.frost * (root.hovered ? 1.0 : 0.75)
        Behavior on opacity { NumberAnimation { duration: 200 } }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            var w = width
            var h = height
            ctx.clearRect(0, 0, w, h)
            if (w <= 0 || h <= 0) return

            // Обрезка по скруглению
            var r = Math.max(0, Math.min(root.customRadius - 1, w / 2, h / 2))
            ctx.save()
            ctx.beginPath()
            ctx.moveTo(r, 0)
            ctx.arcTo(w, 0, w, h, r)
            ctx.arcTo(w, h, 0, h, r)
            ctx.arcTo(0, h, 0, 0, r)
            ctx.arcTo(0, 0, w, 0, r)
            ctx.closePath()
            ctx.clip()

            // Детерминированный генератор, чтобы узор не прыгал при перерисовке
            var seed = 7
            function rnd() {
                seed = (seed * 16807) % 2147483647
                return seed / 2147483647
            }

            function branch(x, y, a, len, depth, alpha) {
                if (depth <= 0 || len < 2) return
                var x2 = x + Math.cos(a) * len
                var y2 = y + Math.sin(a) * len
                ctx.strokeStyle = "rgba(214,244,255," + alpha.toFixed(3) + ")"
                ctx.lineWidth = depth > 2 ? 0.8 : 0.5
                ctx.beginPath()
                ctx.moveTo(x, y)
                ctx.lineTo(x2, y2)
                ctx.stroke()
                for (var i = 0; i < 2; ++i) {
                    var da = (0.35 + rnd() * 0.6) * (rnd() < 0.5 ? -1 : 1)
                    branch(x2, y2, a + da, len * (0.5 + rnd() * 0.3), depth - 1, alpha * 0.78)
                }
            }

            var h2 = h * 0.95
            var w2 = w * 0.6
            branch(0, h, -0.35, h2, 4, 0.55)
            branch(0, h, -1.1, h2 * 0.7, 4, 0.4)
            branch(w, 0, Math.PI - 0.4, h2, 4, 0.5)
            branch(w, 0, Math.PI - 1.2, h2 * 0.6, 4, 0.35)
            branch(w * 0.45, 0, Math.PI / 2 + 0.25, h2 * 0.5, 3, 0.3)

            ctx.restore()
        }
    }
}
