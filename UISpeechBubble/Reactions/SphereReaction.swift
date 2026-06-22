//
//  SphereReaction.swift
//  UISpeechBubble
//
// Created by Johny Vu on 6/20/26
//
//  The contract every "sphere movement" implements. Each reaction style lives in
//  its own file in this folder so you can tweak or swap one without touching the
//  others. DotSphereScene holds one active `SphereReaction` and calls `deform`
//  once per dot, per frame.
//

import simd
import Foundation

protocol SphereReaction {

    /// Move a single dot for this frame.
    ///
    /// - Parameters:
    ///   - point:  the dot's resting position on the unit sphere (radius ~1).
    ///   - random: a stable per-dot value in 0...1, the same every frame for a
    ///             given dot — used by styles that need per-dot variety (e.g. dissolve).
    ///   - level:  smoothed voice loudness, 0 (silent) ... 1 (loud).
    ///   - drive:  max(level, a gentle idle breathing pulse). Use this for motion
    ///             that should keep ticking when silent; use `level` for motion
    ///             that should rest at silence.
    ///   - time:   seconds since the scene started, for animating the pattern.
    /// - Returns: the dot's new position. Still roughly unit-scale — the scene
    ///            applies camera rotation, screen size, and perspective afterward.
    func deform(point: SIMD3<Float>, random: Float, level: Double, drive: Double, time: TimeInterval) -> SIMD3<Float>
}
