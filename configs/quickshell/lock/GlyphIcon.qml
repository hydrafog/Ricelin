import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell

/**
 * Bold macOS Tahoe glyphs for the lock: maps to MacTahoe symbolic icons
 * with fallback to baked vector shapes at bold stroke (2.4).
 */
Item {
    id: root

    property string name: ""
    property color color: Theme.dim
    property color duoColor: Theme.verm
    property real stroke: 2.4

    readonly property real u: Math.min(width, height) / 24

    readonly property var iconMap: ({
        "eye": "view-visible-symbolic",
        "eye-off": "view-hidden-symbolic"
    })

    readonly property string macIconName: iconMap[root.name] || ""
    readonly property string iconSource: macIconName ? Quickshell.iconPath(macIconName, true) : ""
    readonly property bool hasSystemIcon: iconSource.length > 0 && iconImg.status === Image.Ready

    Image {
        id: iconImg
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
        source: root.iconSource
        sourceSize: Qt.size(width, height)
        visible: false
        asynchronous: false
    }

    MultiEffect {
        id: iconEffect
        anchors.fill: iconImg
        source: iconImg
        colorization: 1.0
        colorizationColor: root.color
        brightness: 1.0
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.90)
        shadowBlur: 2.2
        shadowVerticalOffset: 1.0
        visible: root.hasSystemIcon
    }

    readonly property var glyphs: ({
        "eye": { d: "M15 12C15 13.6569 13.6569 15 12 15C10.3431 15 9 13.6569 9 12C9 10.3431 10.3431 9 12 9C13.6569 9 15 10.3431 15 12Z", d2: "M3.27489 15.2957C2.42496 14.1915 2 13.6394 2 12C2 10.3606 2.42496 9.80853 3.27489 8.70433C4.97196 6.49956 7.81811 4 12 4C16.1819 4 19.028 6.49956 20.7251 8.70433C21.575 9.80853 22 10.3606 22 12C22 13.6394 21.575 14.1915 20.7251 15.2957C19.028 17.5004 16.1819 20 12 20C7.81811 20 4.97196 17.5004 3.27489 15.2957Z ", df2: "", d2b: "", o2: 0.5, o2b: 0.5, fill: false },
        "eye-off": { d: "M12 14C5 14 2 7 2 7M22 7C22 7 21.0586 9.19661 19 11.1288C18.0872 11.9856 16.9547 12.7904 15.5872 13.3287C14.5334 13.7435 13.34 14 12 14M12 14V16.5M15.5872 13.3287L17 15.5M19 11.1288L20.5 12.6288M8.41281 13.3287L7 15.5M5 11.1288L3.5 12.6288", d2: "", df2: "", d2b: "", o2: 0.5, o2b: 0.5, fill: false },
    })
    readonly property var g: glyphs[name] !== undefined ? glyphs[name] : ({ d: "", d2: "", df2: "", d2b: "", o2: 0.5, o2b: 0.5, fill: false })

    Shape {
        id: glyph
        visible: !root.hasSystemIcon && root.g.d.length > 0
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
