pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "Singletons"

/**
 * Workspace switch indicator for the workspace OSD flash: a fixed run of ten
 * bare cells (workspaces 1-10, always present whether populated or not), no
 * backgrounds. Each populated cell arranges its opened-window app icons into a
 * growing square matrix — 1x1, 2x2, then 3x3 — past which the corner slot
 * becomes a +n chip. The active cell gains a vermillion outline; empty ones
 * carry a lone marker dot. Clicking a cell focuses the workspace, clicking an
 * icon focuses that window, both via the Hyprland-lua dispatcher.
 *
 * Window icons reflect this monitor only, so a rule-driven multi-screen setup
 * still reads true per pill.
 */
Item {
    id: root

    property string screenName: ""
    property real s: 1

    /** Matrix shape limits per cell. */
    property int maxDim: 3
    property real iconSize: 11 * s
    property real gap: 2 * s
    property real pad: 3 * s

    readonly property int capacity: maxDim * maxDim
    readonly property int wsCount: 10

    readonly property var range: {
        var out = [];
        for (var i = 1; i <= wsCount; i++)
            out.push(i);
        return out;
    }

    readonly property string activeName: {
        var mons = Hyprland.monitors.values;
        for (var i = 0; i < mons.length; i++)
            if (mons[i].name === screenName)
                return mons[i].activeWorkspace ? mons[i].activeWorkspace.name : "";
        return "";
    }

    /** Opened windows keyed by workspace id, this monitor only. */
    readonly property var winsByWs: {
        var map = ({});
        var tl = Hyprland.toplevels.values;
        for (var i = 0; i < tl.length; i++) {
            var t = tl[i];
            if (!t || !t.workspace || t.workspace.id < 1)
                continue;
            var mon = t.workspace.monitor ? t.workspace.monitor.name : "";
            if (mon.length > 0 && mon !== screenName)
                continue;
            var k = String(t.workspace.id);
            if (!map[k])
                map[k] = [];
            map[k].push(t);
        }
        return map;
    }

    /**
     * Resolve an icon path for a toplevel by matching its window class to a
     * desktop entry id, with a direct icon-theme lookup as fallback.
     */
    function iconFor(t) {
        var cls = (t && t.lastIpcObject && t.lastIpcObject.class) ? t.lastIpcObject.class
            : (t && t.wayland && t.wayland.appId ? t.wayland.appId : "");
        if (!cls)
            return "";
        var apps = DesktopEntries.applications.values;
        for (var i = 0; i < apps.length; i++) {
            var e = apps[i];
            if (e && e.id && e.id.toLowerCase() === cls.toLowerCase() && e.icon)
                return Quickshell.iconPath(e.icon, "application-x-executable");
        }
        return Quickshell.iconPath(cls, "application-x-executable");
    }

    function focusWindow(t) {
        var addr = t.address;
        if (addr.indexOf("0x") !== 0)
            addr = "0x" + addr;
        Hyprland.dispatch('hl.dsp.focus({ window = "address:' + addr + '" })');
    }

    implicitWidth: row.implicitWidth
    implicitHeight: maxDim * iconSize + (maxDim - 1) * gap + 2 * pad

    Row {
        id: row
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5 * root.s

        Repeater {
            model: root.range

            delegate: Rectangle {
                id: seg

                required property var modelData

                readonly property string wsName: String(modelData)
                readonly property bool isActive: root.activeName === wsName
                readonly property var wins: root.winsByWs[wsName] || []
                readonly property bool hasWins: wins.length > 0
                readonly property int shown: Math.min(wins.length, root.capacity)
                readonly property int overflow: wins.length - shown

                /** Growing square matrix: 1 window -> 1x1, up to 4 -> 2x2, 9 -> 3x3. */
                readonly property int dim: shown === 0 ? 0
                    : Math.min(root.maxDim, Math.ceil(Math.sqrt(shown)))
                readonly property int slots: dim * dim

                /** Icons actually drawn, reserving the corner slot for +n. */
                readonly property int drawn: overflow > 0 ? Math.min(shown, slots - 1) : shown

                width: dim === 0 ? 15 * root.s : dim * root.iconSize + (dim - 1) * root.gap + 2 * root.pad
                height: dim === 0 ? 15 * root.s : dim * root.iconSize + (dim - 1) * root.gap + 2 * root.pad
                radius: Motion.rSmall * root.s
                color: "transparent"
                border.width: 1
                border.color: isActive ? Qt.alpha(Theme.vermLit, 0.55)
                    : (area.containsMouse ? Theme.hair : "transparent")
                Behavior on border.color { ColorAnimation { duration: Motion.fast } }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    anchors.margins: -3 * root.s
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch('hl.dsp.focus({workspace="' + seg.wsName + '"})')
                }

                /** Lone marker for an empty workspace. */
                Rectangle {
                    anchors.centerIn: parent
                    width: 5 * root.s
                    height: 5 * root.s
                    radius: height / 2
                    visible: !seg.hasWins
                    color: seg.isActive ? Theme.vermLit : Theme.cream
                    opacity: seg.isActive ? 1.0 : (area.containsMouse ? 0.7 : 0.3)
                    Behavior on opacity { NumberAnimation { duration: Motion.fast } }
                }

                GridLayout {
                    id: grid
                    anchors.centerIn: parent
                    columns: seg.dim
                    columnSpacing: root.gap
                    rowSpacing: root.gap
                    visible: seg.hasWins

                    Repeater {
                        model: seg.slots

                        delegate: Item {
                            id: win

                            required property int index

                            readonly property bool isPlus: seg.overflow > 0
                                && win.index === seg.slots - 1
                            readonly property bool live: win.index < seg.drawn || win.isPlus
                            readonly property var tl: (win.index < seg.drawn && !win.isPlus) ? seg.wins[win.index] : null
                            readonly property string iconSrc: win.tl ? root.iconFor(win.tl) : ""

                            Layout.preferredWidth: root.iconSize
                            Layout.preferredHeight: root.iconSize
                            visible: win.live

                            Image {
                                anchors.fill: parent
                                sourceSize.width: Math.round(22 * root.s)
                                sourceSize.height: Math.round(22 * root.s)
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                smooth: true
                                visible: !win.isPlus
                                source: win.iconSrc
                                opacity: winArea.containsMouse ? 1 : (seg.isActive ? 0.95 : 0.72)
                                Behavior on opacity { NumberAnimation { duration: Motion.fast } }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: win.isPlus
                                text: "+" + seg.overflow
                                color: seg.isActive ? Theme.cream : Theme.subtle
                                font.family: Theme.font
                                font.pixelSize: 9 * root.s
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                id: winArea
                                anchors.fill: parent
                                anchors.margins: -2 * root.s
                                hoverEnabled: true
                                enabled: !win.isPlus && win.tl !== null
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.focusWindow(win.tl)
                            }

                            Tooltip {
                                s: root.s
                                placement: "below"
                                title: win.tl ? win.tl.title : ""
                                show: winArea.containsMouse
                            }
                        }
                    }
                }
            }
        }
    }
}
