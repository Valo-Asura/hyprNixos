pragma Singleton
import QtQuick
import Quickshell

/**
 * Centralized motion timing constants for the morph engine.
 * Ported from ricelin's pill Motion singleton with vibeshell's config awareness.
 *
 * The liquid morph curve is front-loaded like an exponential chase but with a
 * long visible settle tail, giving surfaces a tangible weight when they grow
 * out of the notch.
 */
Singleton {
    readonly property int fast:       140
    readonly property int standard:   300
    readonly property int morph:      420
    readonly property int shapeshift: 820
    readonly property int glide:      260
    readonly property int heat:      1100
    readonly property int easeStandard: Easing.OutCubic
    readonly property int easeMorph:    Easing.BezierSpline

    /**
     * Liquid morph curve: cubic-bezier(0.16, 1, 0.3, 1).
     * Use with easeMorph (BezierSpline). The six-element array format is
     * Qt's bezierCurve convention: [cp1x, cp1y, cp2x, cp2y, endx, endy].
     */
    readonly property var morphCurve: [0.16, 1, 0.3, 1, 1, 1]

    /** Tile corner radius presets for surface elements. */
    readonly property real rSmall: 7
    readonly property real rTile:  13

    /** Looping scan/pairing breath pulse duration. */
    readonly property int pulse: 420
}
