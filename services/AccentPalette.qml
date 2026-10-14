pragma Singleton
import QtQuick
import qs.theme

Item {
    id: root

    implicitWidth: 0
    implicitHeight: 0

    readonly property string currentAccent: (Theme.accent ?? "").toLowerCase()
    readonly property bool isCustom: currentAccent === "custom"
    readonly property string currentAccentSource: {
        const raw = (Theme.accentSource ?? "").toString().trim();
        if (raw.length === 6)
            return "#" + raw;
        return raw;
    }

    function applyCustom(hex) {
        ThemeService.generateFromColor(hex, "custom");
    }

    function revert() {
        ThemeService.revertTheme();
    }
}