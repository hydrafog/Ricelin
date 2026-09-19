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
    property color onGlow: "#007aff"
    Behavior on onGlow { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color verm:     dyn ? Qt.darker(Dyn.primary, 1.18) : "#0062cc"
    Behavior on verm { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color vermLit:  dyn ? Dyn.primary : "#007aff"
    Behavior on vermLit { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color vermDeep: dyn ? Dyn.primaryContainer : "#004999"
    Behavior on vermDeep { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color cream:    "#ffffff"
    Behavior on cream { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color bright:   "#ffffff"
    Behavior on bright { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color dim:      "#d1d1d6"
    Behavior on dim { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color cardTop:  Qt.rgba(1, 1, 1, 0.16)
    Behavior on cardTop { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color cardBot:  Qt.rgba(1, 1, 1, 0.12)
    Behavior on cardBot { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color activeBorder: Qt.rgba(0, 122, 255, 0.60)
    Behavior on activeBorder { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color border:   Qt.rgba(1, 1, 1, 0.20)
    readonly property color borderRing: Qt.rgba(1, 1, 1, 0.15)
    Behavior on border { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color shadow:     Qt.rgba(0, 0, 0, 0.40)
    property color tileBg:   Qt.rgba(1, 1, 1, 0.08)
    Behavior on tileBg { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color subtle:   "#8e8e93"
    Behavior on subtle { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color faint:    "#636366"
    Behavior on faint { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color iconDim:  "#ffffff"
    Behavior on iconDim { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    readonly property color hair:     Qt.alpha(cream, 0.13)
    readonly property color hairSoft: Qt.alpha(cream, 0.08)
    readonly property color sheen:    "transparent"
    property color vermDim:   "#0051a8"
    Behavior on vermDim { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color vermDimDeep: "#003c7d"
    Behavior on vermDimDeep { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color vermBurn:  "#002e60"
    Behavior on vermBurn { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color tickRest:  "#86868b"
    Behavior on tickRest { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    readonly property color threadBg:  Qt.alpha(cream, 0.08)
    property color flameCore: "#5ac8fa"
    Behavior on flameCore { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color flameGlow: "#007aff"
    Behavior on flameGlow { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    readonly property string flameInk:   "#007aff"
    readonly property string flameEmber: "#004999"
    readonly property string flameBurn:  "#002e60"
    readonly property string flameTip:   "#5ac8fa"
    property color todayWarm: "#007aff"
    Behavior on todayWarm { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property color ghost:     Qt.rgba(1, 1, 1, 0.08)
    Behavior on ghost { ColorAnimation { duration: 1200; easing.type: Easing.OutCubic } }
    readonly property color frameBg:      Qt.rgba(1, 1, 1, 0.06)
    readonly property color frameBorder:  Qt.rgba(1, 1, 1, 0.12)
    readonly property color creamMenu:     cream
    readonly property real shadowOpacity: 0.25
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
