pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQml

Singleton {

    property var workspaceStates: []
    property var monitorStates: []

    function refresh() {
        const workspaces = Hyprland.workspaces.values;
        const next = [];
        for (let i = 0; i < workspaces.length; i++) {
            const ws = workspaces[i];
            next.push({
                id: ws.id,
                hasFullscreen: !!ws.hasFullscreen,
                monitorName: ws && ws.monitor ? ws.monitor.name : null
            });
        }
        workspaceStates = next;

        const monitors = Hyprland.monitors.values;
        const mons = [];
        for (let i = 0; i < monitors.length; i++) {
            const m = monitors[i];
            const ipc = m.lastIpcObject;
            const sp = ipc ? ipc.specialWorkspace : null;
            const specialId = sp && typeof sp.id === "number" ? sp.id : 0;
            const aw = m.activeWorkspace;
            mons.push({
                name: m.name,
                specialId: specialId,
                activeWsId: aw ? aw.id : -1,
                activeWsFs: aw ? !!aw.hasFullscreen : false
            });
        }
        monitorStates = mons;
    }

    function stateForMonitor(monitor) {
        const name = monitor ? monitor.name : null;
        for (let i = 0; i < monitorStates.length; i++) {
            if (monitorStates[i].name === name)
                return monitorStates[i];
        }
        return null;
    }

    function isFullscreen(monitor) {
        if (!monitor)
            return false;

        const state = stateForMonitor(monitor);
        if (state === null)
            return false;

        if (state.specialId !== 0) {
            for (let i = 0; i < workspaceStates.length; i++) {
                if (workspaceStates[i].id === state.specialId)
                    return workspaceStates[i].hasFullscreen;
            }
            return false;
        }

        if (state.activeWsFs)
            return true;

        for (let i = 0; i < workspaceStates.length; i++) {
            if (workspaceStates[i].id === state.activeWsId)
                return workspaceStates[i].hasFullscreen;
        }
        return false;
    }

    component Poller: Timer {
        interval: 120
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: FullscreenState.refresh()
    }

    Poller {
        id: poller
    }
}
