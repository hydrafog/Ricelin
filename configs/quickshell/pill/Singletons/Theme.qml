pragma Singleton
import QtQuick
import Quickshell

/**
 * Pill palette. Two sources: the curated washi/flame hex below is the identity
 * and the default, used whenever the dynamic-palette flag is off. With the flag
 * on, the surfaces and the whole accent ramp follow the wallpaper through the
 * matugen-fed `Dyn` singleton, while the text family, light veils and shadow
 * stay locked here so copy keeps its contrast on any generated background. Each
 * token is a single ternary, so static mode renders byte-identical to the fixed
 * theme and only the colours that should breathe with the wallpaper do.
 */
Singleton {
    readonly property bool dyn: Flags.paletteMode !== "static"

    /**
     * Bright warm pop shared by the flame glow, charging glyphs, the recording
     * countdown, the unread inbox dot, the calendar's today cell and the held
     * power tile. The dynamic branch uses the wallpaper accent (Dyn.primary):
     * matugen's on-primary-container does not populate here and collapses the
     * token to black, while the accent always loads and contrasts the pill
     * surface. Static mode keeps the fixed warm hex.
     */
    property color onGlow: dyn ? Dyn.primary : "#ff9a64"
    Behavior on onGlow { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color verm:     dyn ? Qt.darker(Dyn.primary, 1.18) : "#c0442b"
    Behavior on verm { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color vermLit:  dyn ? Dyn.primary : "#e0563b"
    Behavior on vermLit { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color vermDeep: dyn ? Dyn.primaryContainer : "#a3371f"
    Behavior on vermDeep { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color cream:    dyn ? Dyn.cream : "#e6d6cb"
    Behavior on cream { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color bright:   dyn ? Dyn.bright : "#fff6f0"
    Behavior on bright { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color dim:      dyn ? Dyn.dim : "#8a7d74"
    Behavior on dim { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color cardTop:  dyn ? Qt.alpha(Dyn.surfaceContainerHigh, 0.40) : Qt.rgba(1, 1, 1, 0.08)
    Behavior on cardTop { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color cardBot:  dyn ? Qt.alpha(Dyn.surfaceContainerLow, 0.50) : Qt.rgba(1, 1, 1, 0.08)
    Behavior on cardBot { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color activeBorder: dyn ? Qt.alpha(Dyn.primary, 0.40) : Qt.alpha(vermLit, 0.40)
    Behavior on activeBorder { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color border:   dyn ? Qt.alpha(bright, 0.20) : Qt.rgba(1, 1, 1, 0.20)
    Behavior on border { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color shadow:     Qt.rgba(0, 0, 0, 0.35)
    property color tileBg:   dyn ? Qt.alpha(Dyn.surface, 0.40) : Qt.rgba(1, 1, 1, 0.05)
    Behavior on tileBg { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color subtle:   dyn ? Dyn.subtle : "#b9a99e"
    Behavior on subtle { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color faint:    dyn ? Dyn.faint : "#6f635b"
    Behavior on faint { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color iconDim:  dyn ? Dyn.iconDim : "#cdbfb4"
    Behavior on iconDim { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    readonly property color hair:     Qt.alpha(cream, 0.13)
    readonly property color hairSoft: Qt.alpha(cream, 0.08)
    readonly property color sheen:    Qt.alpha(cream, 0.07)
    property color vermDim:   dyn ? Qt.darker(Dyn.primary, 1.5) : "#8a5440"
    Behavior on vermDim { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color vermDimDeep: dyn ? Qt.darker(Dyn.primary, 2.2) : "#5a3526"
    Behavior on vermDimDeep { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color vermBurn:  dyn ? Qt.darker(Dyn.primaryContainer, 1.1) : "#8a2c14"
    Behavior on vermBurn { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color tickRest:  dyn ? Dyn.tickRest : "#cbb6a3"
    Behavior on tickRest { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    readonly property color threadBg:  Qt.alpha(cream, 0.13)
    property color flameCore: dyn ? Qt.lighter(onGlow, 1.03) : "#ffd9c2"
    Behavior on flameCore { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color flameGlow: dyn ? onGlow : "#ff9a64"
    Behavior on flameGlow { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    /**
     * Flame canvas ramp: literal hex strings (color type won't work), fed
     * directly to Canvas addColorStop/strokeStyle. A color property serializes
     * to #aarrggbb and corrupts the gradient render, so the dynamic branch passes
     * matugen's raw hex strings through untouched rather than any Qt.darker math.
     */
    readonly property string flameInk:   dyn ? Dyn.primary : "#f0795a"
    readonly property string flameEmber: dyn ? Dyn.primaryContainer : "#7e2812"
    readonly property string flameBurn:  dyn ? Dyn.primaryContainer : "#8a2c14"
    readonly property string flameTip:   dyn ? Dyn.onPrimaryContainer : "#ffb38a"
    property color todayWarm: dyn ? onGlow : "#ffb38a"
    Behavior on todayWarm { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color ghost:     dyn ? Dyn.surfaceContainerHighest : "#594636"
    Behavior on ghost { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }
    readonly property color frameBg:      dyn ? Qt.alpha(bright, 0.08) : Qt.rgba(1, 1, 1, 0.08)
    readonly property color frameBorder:  dyn ? Qt.alpha(bright, 0.20) : Qt.rgba(1, 1, 1, 0.20)
    readonly property color creamMenu:     Qt.alpha(cream, 0.82)
    readonly property real shadowOpacity: 0.35
    /**
     * Snapshot of the system families, not a binding: Qt.fontFamilies() is not
     * notifiable, so a font dropped onto the pill re-registers through
     * refreshFonts() once its FontLoader is ready.
     */
    property var fontFamilies: Qt.fontFamilies()
    function refreshFonts() { fontFamilies = Qt.fontFamilies(); }
    readonly property string font: (Flags.uiFont.length > 0 && fontFamilies.indexOf(Flags.uiFont) >= 0) ? Flags.uiFont : "SF Pro Display"
    readonly property string fontJp: "Zen Kaku Gothic New"

    /**
     * MPRIS trackArtists arrives as a JS array from some players and as a
     * plain string from others (Spotify); calling join on the string throws
     * and kills the whole binding. Handles both, falls back to trackArtist.
     */
    function joinArtists(artists, single) {
        if (artists && typeof artists.join === "function" && artists.length > 0)
            return artists.join(", ");
        if (artists && String(artists).length > 0)
            return String(artists);
        return single ? String(single) : "";
    }
}
