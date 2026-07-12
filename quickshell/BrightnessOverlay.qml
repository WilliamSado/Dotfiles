import Quickshell
import QtQuick

PanelWindow {
    id: overlay

    required property int brightnessPercent
    readonly property real dimOpacity: Math.max(0, Math.min(0.72, (100 - brightnessPercent) / 100 * 0.72))

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    visible: dimOpacity > 0.001
    color: Qt.rgba(0, 0, 0, dimOpacity)
    exclusionMode: ExclusionMode.Ignore

    mask: Region {}
}
