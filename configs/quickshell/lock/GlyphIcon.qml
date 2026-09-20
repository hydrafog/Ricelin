import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell

/**
 * MingCute line icon renderer for the lock screen.
 * Renders authentic MingCute line icons (https://icon-sets.iconify.design/mingcute/)
 * with pure 2px stroke vector shapes and soft drop shadow.
 */
Item {
    id: root

    property string name: ""
    property color color: Theme.dim
    property color duoColor: Theme.verm
    property real stroke: 2.0

    readonly property real u: Math.min(width, height) / 24

    readonly property var glyphs: ({
        "eye": { d: "M21 12c0 2.5-4.03 7-9 7s-9-4.5-9-7s4.03-7 9-7s9 4.5 9 7Z M11.012 10.262a3 3 0 0 0 2.725 2.725A1.997 1.997 0 0 1 10 12c0-.745.408-1.394 1.012-1.738Z" },
        "eye-off": { d: "m14.33 14.693l.646 2.415m3.388-4.744l1.768 1.768m-10.462.561l-.647 2.415m-3.387-4.744l-1.768 1.768M4 9c2.36 7.965 13.64 7.965 16 0" }
    })

    readonly property var g: glyphs[name] !== undefined ? glyphs[name] : ({ d: "" })

    Shape {
        id: glyph
        visible: root.g.d && root.g.d.length > 0
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.90)
            shadowBlur: 2.2
            shadowVerticalOffset: 1.0
        }

        width: 24
        height: 24
        scale: root.u
        transformOrigin: Item.TopLeft
        x: glyph.boundingRect.width > 0
           ? root.width / 2 - (glyph.boundingRect.x + glyph.boundingRect.width / 2) * root.u
           : (root.width - 24 * root.u) / 2
        y: glyph.boundingRect.height > 0
           ? root.height / 2 - (glyph.boundingRect.y + glyph.boundingRect.height / 2) * root.u
           : (root.height - 24 * root.u) / 2
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.color
            fillColor: "transparent"
            strokeWidth: root.stroke
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: root.g.d ? root.g.d : "M0 0" }
        }
    }
}
