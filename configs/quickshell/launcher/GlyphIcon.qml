import QtQuick
import QtQuick.Shapes

/**
 * Baked vector glyph for the standalone launcher, same 24x24 Solar recipe as
 * the pill's GlyphIcon but trimmed to the single return-arrow the launcher
 * needs, with its official LineDuotone secondary in `duoColor`.
 * Local warm tokens only, never the pill or lock Theme singletons, so
 * the launcher stays an isolated feature.
 */
Item {
    id: root

    property string name: ""
    property color color: "#fff6f0"
    property color duoColor: "#c0442b"
    property real stroke: 1.8

    readonly property real u: Math.min(width, height) / 24

    readonly property var glyphs: ({
        "return": { d: "M7 10L4 7L7 4", d2: "M4 7H15C16.8692 7 17.8039 7 18.5 7.40193C18.9561 7.66523 19.3348 8.04394 19.5981 8.49999C20 9.19615 20 10.1308 20 12C20 13.8692 20 14.8038 19.5981 15.5C19.3348 15.9561 18.9561 16.3348 18.5 16.5981C17.8039 17 16.8692 17 15 17H8.00001", df2: "", d2b: "", o2: 0.5, o2b: 0.5, fill: false },
    })
    readonly property var g: glyphs[name] !== undefined ? glyphs[name] : ({ d: "", d2: "", df2: "", d2b: "", o2: 0.5, o2b: 0.5, fill: false })

    Shape {
        id: glyph

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
            strokeColor: root.g.d2 === "" ? "transparent" : Qt.alpha(root.duoColor, root.g.o2)
            fillColor: "transparent"
            strokeWidth: root.stroke
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: root.g.d2 === "" ? "M0 0" : root.g.d2 }
        }

        ShapePath {
            strokeColor: "transparent"
            fillColor: root.g.df2 === "" ? "transparent" : Qt.alpha(root.duoColor, root.g.o2)
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: root.g.df2 === "" ? "M0 0" : root.g.df2 }
        }

        ShapePath {
            strokeColor: root.g.d2b === "" ? "transparent" : Qt.alpha(root.duoColor, root.g.o2b)
            fillColor: "transparent"
            strokeWidth: root.stroke
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: root.g.d2b === "" ? "M0 0" : root.g.d2b }
        }

        ShapePath {
            strokeColor: root.g.fill ? "transparent" : root.color
            fillColor: root.g.fill ? root.color : "transparent"
            strokeWidth: root.stroke
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: root.g.d }
        }
    }
}
