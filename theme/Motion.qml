pragma Singleton

import QtQuick

QtObject {

    readonly property int standardSmall: 0
    readonly property int standard: 1
    readonly property int standardLarge: 2
    readonly property int standardExtraLarge: 3

    readonly property int emphasizedSmall: 4
    readonly property int emphasized: 5
    readonly property int emphasizedLarge: 6
    readonly property int emphasizedExtraLarge: 7

    readonly property int fastSpatial: 8
    readonly property int defaultSpatial: 9
    readonly property int slowSpatial: 10

    readonly property int fastEffects: 11
    readonly property int defaultEffects: 12
    readonly property int slowEffects: 13


    function duration(type) {
        switch (type) {
        case standardSmall:
        case emphasizedSmall:
            return 200;
        case standard:
        case emphasized:
            return 400;
        case standardLarge:
        case emphasizedLarge:
            return 600;
        case standardExtraLarge:
        case emphasizedExtraLarge:
            return 1000;
        case fastSpatial:
            return 350;
        case defaultSpatial:
            return 500;
        case slowSpatial:
            return 650;
        case fastEffects:
            return 150;
        case defaultEffects:
            return 200;
        case slowEffects:
            return 300;
        }
        return 500;
    }


    function curve(type) {
        switch (type) {
        case standardSmall:
        case standard:
        case standardLarge:
        case standardExtraLarge:
            return [0.2, 0, 0, 1];
        case emphasizedSmall:
        case emphasized:
        case emphasizedLarge:
        case emphasizedExtraLarge:
            return [0.05, 0, 0.25, 1];
        case fastSpatial:
            return [0.42, 1.67, 0.21, 0.9];
        case defaultSpatial:
            return [0.38, 1.21, 0.22, 1];
        case slowSpatial:
            return [0.39, 1.29, 0.35, 0.98];
        case fastEffects:
            return [0.31, 0.94, 0.34, 1];
        case defaultEffects:
            return [0.34, 0.8, 0.34, 1];
        case slowEffects:
            return [0.34, 0.88, 0.34, 1];
        }
        return [0.38, 1.21, 0.22, 1];
    }

    function component(u, a, b) {
        const m = 1 - u;
        return 3 * m * m * u * a + 3 * m * u * u * b + u * u * u;
    }

    function ease(points, t) {
        if (t <= 0)
            return 0;
        if (t >= 1)
            return 1;

        const x1 = points[0], y1 = points[1], x2 = points[2], y2 = points[3];
        let u = t;

        for (let i = 0; i < 8; i++) {
            const err = component(u, x1, x2) - t;
            if (Math.abs(err) < 1e-6)
                return component(u, y1, y2);
            const slope = 3 * (1 - u) * (1 - u) * x1
                + 6 * (1 - u) * u * (x2 - x1)
                + 3 * u * u * (1 - x2);
            if (Math.abs(slope) < 1e-6)
                break;
            u -= err / slope;
        }

        let lo = 0, hi = 1;
        u = t;
        while (hi - lo > 1e-6) {
            if (component(u, x1, x2) < t)
                lo = u;
            else
                hi = u;
            u = (lo + hi) / 2;
        }
        return component(u, y1, y2);
    }

    readonly property int offscreenGap: 5
}