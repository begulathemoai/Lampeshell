pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var simpleTags: ["b", "i", "u", "s", "br", "br/"]

    function escapeHtml(s) {
        return s.replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;");
    }

    function sanitize(body) {
        if (!body)
            return "";
        let s = escapeHtml(body);

        const simple = simpleTags.join("|");
        s = s.replace(new RegExp("&lt;(/?)(" + simple + ")\\s*/?&gt;", "gi"), "<$1$2>");

        s = s.replace(/&lt;a\s+href=&quot;((?:https?|mailto):[^&]*)&quot;\s*&gt;/gi, '<a href="$1">');
        s = s.replace(/&lt;\/a&gt;/gi, "</a>");

        return s;
    }
}