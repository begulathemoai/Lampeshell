pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQml

Singleton {
    // Fullscreen state is polled rather than bound.
    //
    // In Quickshell 0.3.1 none of the obvious properties notify when they change:
    //   - HyprlandWorkspace.hasFullscreen never emits notify, so a binding that
    //     reads it is evaluated once and frozen. That left the bar stuck in its
    //     fullscreen state after leaving fullscreen: the surface came back but
    //     its children stayed hidden, which is the "children detach / bar comes
    //     back blank" symptom.
    //   - HyprlandToplevel.lastIpcObject is a one-time snapshot here, so the
    //     `toplevels.values.some(t => t.lastIpcObject.fullscreen > 1)` check that
    //     Caelestia uses never sees a change either.
    //
    // Reading the values on a timer sidesteps both: the underlying values are
    // kept current by Hyprland's IPC, they just do not announce it. Re-assigning
    // the snapshot properties makes dependent bindings re-evaluate.

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

        // Which special workspace is actually DISPLAYED per monitor.
        //
        // A monitor can have several special workspaces lingering (Discord keeps
        // special:communication around), so picking any workspace with a negative
        // id is wrong - the bar would then never hide. lastIpcObject is the raw
        // monitor payload and is the only place that says which special
        // workspace is currently shown; polling picks up Hyprland's updates.
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

        // A special workspace is displayed over the normal one, so
        // activeWorkspace says nothing about what is actually on screen.
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