pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import "Singletons"

/**
 * Workspace switch indicator for the workspace OSD flash: one rounded segment
 * per workspace on this monitor, each carrying the app icons of its opened
 * windows (capped at three, with a +n chip past that) instead of bare dots.
 * The active segment lights up vermillion; empty ones shrink to a lone marker
 * dot. Clicking a segment focuses the workspace, clicking an icon focuses that
 * window, both via the Hyprland-lua dispatcher.
 *
 * The segment range unions this monitor's workspace rules ([[Workspacerules]])
 * with the workspaces Hyprland currently has on it, matching the old dot strip,
 * so rule-driven setups always show every assigned segment.
 */
Item {
    id: root

    property string screenName: ""
    property real s: 1

    readonly property var range: {
        var out = [];
        var seen = ({});
        var ruled = Workspacerules.byMonitor[screenName];
        if (ruled && ruled.length) {
            for (var r = 0; r < ruled.length; r++) {
                if (!seen[ruled[r]]) {
                    seen[ruled[r]] = true;
                    out.push(ruled[r]);
                }
            }
        }

        var wss = Hyprland.workspaces.values;
        for (var i = 0; i < wss.length; i++) {
            var w = wss[i];
            if (w.id >= 1 && w.monitor && w.monitor.name === screenName && !seen[w.id]) {
                seen[w.id] = true;
                out.push(w.id);
            }
        }
        var a = parseInt(activeName);
        if (a >= 1 && !seen[a])
            out.push(a);
        out.sort(function (x, y) { return x - y; });
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

    property real segH: 30 * s
    property int maxIcons: 3

    implicitWidth: row.implicitWidth
    implicitHeight: segH

    Row {
        id: row
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6 * root.s

        Repeater {
            model: root.range

            delegate: Rectangle {
                id: seg

                required property var modelData

                readonly property string wsName: String(modelData)
                readonly property bool isActive: root.activeName === wsName
                readonly property var wins: root.winsByWs[wsName] || []
                readonly property bool hasWins: wins.length > 0
                readonly property int shown: Math.min(wins.length, root.maxIcons)
                readonly property int overflow: wins.length - shown

                radius: height / 2
                height: root.segH
                width: hasWins ? iconsRow.implicitWidth + 18 * root.s : 26 * root.s
                Behavior on width { NumberAnimation { duration: Motion.fast; easing.type: Motion.easeStandard } }

                color: isActive ? Qt.alpha(Theme.vermLit, 0.12) : Theme.tileBg
                border.width: 1
                border.color: isActive ? Qt.alpha(Theme.vermLit, 0.55)
                    : (area.containsMouse ? Theme.hair : Qt.alpha(Theme.cream, 0.08))
                Behavior on border.color { ColorAnimation { duration: Motion.fast } }
                Behavior on color { ColorAnimation { duration: Motion.fast } }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    anchors.margins: -4 * root.s
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

                Row {
                    id: iconsRow
                    anchors.centerIn: parent
                    spacing: 5 * root.s
                    visible: seg.hasWins

                    Repeater {
                        model: seg.shown

                        delegate: Item {
                            id: win

                            required property int index

                            width: 17 * root.s
                            height: 17 * root.s
                            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

                            readonly property var tl: seg.wins[win.index]
                            readonly property string iconSrc: root.iconFor(win.tl)

                            Image {
                                anchors.fill: parent
                                sourceSize.width: Math.round(34 * root.s)
                                sourceSize.height: Math.round(34 * root.s)
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                smooth: true
                                source: win.iconSrc
                                opacity: winArea.containsMouse ? 1 : (seg.isActive ? 0.95 : 0.7)
                                Behavior on opacity { NumberAnimation { duration: Motion.fast } }
                            }

                            MouseArea {
                                id: winArea
                                anchors.fill: parent
                                anchors.margins: -3 * root.s
                                hoverEnabled: true
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

                    Text {
                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        visible: seg.overflow > 0
                        text: "+" + seg.overflow
                        color: seg.isActive ? Theme.cream : Theme.subtle
                        font.family: Theme.font
                        font.pixelSize: 10 * root.s
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }
}
