//@ pragma UseQApplication

import Quickshell
import QtQuick

ShellRoot {
    id: shellRoot

    Bar {
        id: barWindow
    }

    BrightnessOverlay {
        brightnessPercent: barWindow.quickBrightnessPercent
    }

    QuickSettingsEdge {
        targetBar: barWindow
    }
}
