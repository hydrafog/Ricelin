pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland
import "Singletons"

/**
 * Workspace switch indicator for the workspace OSD flash: ten bare marker
 * slots (workspaces 1-10, always present whether populated or not). The
 * active one stretches into a vermillion stick; the rest are small dim dots
 * that brighten on hover. Clicking focuses the workspace via the Hyprland-lua
 * dispatcher.
 */
Item {
    id: root

    property string screenName: ""
    property real s: 1

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

    implicitWidth: row.implicitWidth
    implicitHeight: 14 * s

    Row {
        id: row
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4 * root.s

        Repeater {
            model: root.range

            delegate: Item {
                id: seg

                required property var modelData

                readonly property string wsName: String(modelData)
                readonly property bool isActive: root.activeName === wsName

                width: seg.isActive ? 15 * root.s : 9 * root.s
                height: 14 * root.s
                Behavior on width { NumberAnimation { duration: Motion.fast; easing.type: Motion.easeStandard } }

                Rectangle {
                    anchors.centerIn: parent
                    width: seg.isActive ? parent.width - 2 * root.s : 5 * root.s
                    height: 5 * root.s
                    radius: height / 2
                    color: seg.isActive ? Theme.vermLit : Theme.cream
                    opacity: seg.isActive ? 1.0 : (area.containsMouse ? 0.7 : 0.3)
                    Behavior on opacity { NumberAnimation { duration: Motion.fast } }
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    anchors.margins: -3 * root.s
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch('hl.dsp.focus({workspace="' + seg.wsName + '"})')
                }
            }
        }
    }
}
