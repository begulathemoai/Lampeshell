pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int info: 0
    readonly property int success: 1
    readonly property int warning: 2
    readonly property int error: 3

    property var toasts: []

    readonly property int maxVisible: 3
    readonly property int defaultTimeout: 3000
    readonly property int errorTimeout: 5000

    readonly property Component toastFactory: Toast {}

    function defaultIcon(type) {
        switch (type) {
        case root.success: return "check_circle";
        case root.warning: return "warning";
        case root.error: return "error";
        default: return "info";
        }
    }

    function toast(title, message, icon, type, timeoutMs) {
        if (title === undefined || title === null)
            return null;
        type = type ?? root.info;
        icon = icon || defaultIcon(type);
        timeoutMs = timeoutMs ?? (type === root.error ? root.errorTimeout : root.defaultTimeout);

        let obj = null;
        try {
            obj = toastFactory.createObject(root, {
                title: String(title),
                message: String(message ?? ""),
                icon: String(icon),
                type: type,
                timeoutMs: timeoutMs
            });
        } catch (e) {
            console.warn("lampshell: toast creation failed:", e);
            return null;
        }

        root.toasts = [obj, ...root.toasts];
        if (root.toasts.length > 16)
            root.toasts = root.toasts.slice(0, 16);
        return obj;
    }

    function toastInfo(title, message, icon) { return toast(title, message, icon, root.info); }
    function toastSuccess(title, message, icon) { return toast(title, message, icon, root.success); }
    function toastWarning(title, message, icon) { return toast(title, message, icon, root.warning); }
    function toastError(title, message, icon) { return toast(title, message, icon, root.error); }

    function remove(toast) {
        if (!toast)
            return;
        root.toasts = root.toasts.filter(t => t !== toast);
        toast.destroy();
    }

    function clear() {
        const old = root.toasts;
        root.toasts = [];
        for (const t of old)
            t.destroy();
    }

    IpcHandler {
        target: "toaster"

        function info(title: string, message: string, icon: string): void {
            root.toastInfo(title, message, icon);
        }

        function success(title: string, message: string, icon: string): void {
            root.toastSuccess(title, message, icon);
        }

        function warn(title: string, message: string, icon: string): void {
            root.toastWarning(title, message, icon);
        }

        function error(title: string, message: string, icon: string): void {
            root.toastError(title, message, icon);
        }

        function clear(): void {
            root.clear();
        }

        function list(): string {
            return root.toasts.map(t => t.title).join("\n");
        }
    }
}