pragma Singleton
import QtQuick
import Quickshell

/**
 * Lock palette, same split as the pill's Theme: the fixed hex is the identity
 * and the default, and with the dynamic-palette flag on the accent and text
 * family follow the wallpaper through Dyn. Each token is a single ternary, so
 * static mode renders byte-identical to the old fixed theme.
 */
Singleton {
    readonly property bool dyn: Flags.paletteMode !== "static"

    property color verm:   dyn ? Qt.darker(Dyn.primary, 1.18) : "#c0442b"
    Behavior on verm { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color cream:  dyn ? Dyn.cream : "#f5ebe1"
Behavior on cream { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color bright: dyn ? Dyn.bright : "#fff6f0"
    Behavior on bright { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color dim:    dyn ? Dyn.dim : "#f7f5f4"
    Behavior on dim { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    readonly property string font:  "SF Pro Display"

    readonly property color fieldBg: dyn ? Qt.alpha(bright, 0.08) : Qt.alpha(bright, 0.08)
    readonly property color fieldBorder: dyn ? Qt.alpha(bright, 0.20) : Qt.alpha(bright, 0.20)
    readonly property color trackBg: dyn ? Qt.alpha(cream, 0.16) : Qt.alpha(cream, 0.16)

    property color error:  dyn ? Dyn.primary : "#e0563b"
    Behavior on error { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }
}
