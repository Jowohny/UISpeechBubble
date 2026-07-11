//
//  LevelProcessor.swift
//  UISpeechBubble
//
// Created by Johny Vu on 6/13/26.

import Foundation

struct LevelProcessor {

    // MARK: Tunables (final feel is dialed in during Unit 7)

    /// Attack time constant in seconds. Smaller = snappier rise (peaks pop faster,
    /// less perceived delay — but too small reintroduces frame-to-frame jitter).
    var attackTime: Double = 0.025
    /// Release time constant in seconds. Smaller = snappier fall.
    var releaseTime: Double = 0.2
    /// Raw RMS at/below this is treated as silence (gates room hiss). Sits just under
    /// `minPeak` so real speech still passes while ambient hiss no longer feeds the
    /// adaptive-gain normalizer — the sphere rests fully instead of twitching when quiet.
    var noiseFloor: Double = 0.01
    /// Lower bound for the adaptive peak so quiet inputs don't get over-amplified.
    /// Lower = more sensitive (moderate speech reaches the top of the range sooner).
    var minPeak: Double = 0.018
    /// Per-second decay applied to the running peak so gain re-adapts when the
    /// speaker gets quieter. Expressed as a half-life-ish multiplier per second.
    var peakDecayPerSecond: Double = 0.6

    // MARK: State

    /// Smoothed output in 0...1. This is what the renderer reads.
    private(set) var level: Double = 0
    /// Decaying peak used as the normalization reference.
    private var runningPeak: Double

    init() {
        runningPeak = minPeak
    }

    /// Advance the processor by one step.
    /// - Parameters:
    ///   - rawRMS: linear RMS amplitude from the mic (typically ~0...0.3 for voice).
    ///   - deltaTime: seconds since the previous call (e.g. 1/60 at 60fps).
    /// - Returns: the smoothed level in 0...1.
    @discardableResult
    mutating func process(rawRMS: Double, deltaTime: Double) -> Double {
        let dt = max(0, deltaTime)
        let rms = rawRMS.isFinite ? max(0, rawRMS) : 0

        // 1. Noise gate.
        let gated = rms <= noiseFloor ? 0 : rms

        // 2. Adaptive gain: peak rises instantly to new highs, decays slowly.
        let decay = pow(peakDecayPerSecond, dt)
        runningPeak = max(gated, runningPeak * decay)
        runningPeak = max(runningPeak, minPeak)
        let normalized = min(1, gated / runningPeak)

        // 3. Snappy envelope via time-constant smoothing (frame-rate independent).
        let reactiveDirection = normalized > level ? attackTime : releaseTime
        let coeff = reactiveDirection <= 0 ? 1 : 1 - exp(-dt / reactiveDirection)
        level += (normalized - level) * coeff
        level = min(1, max(0, level))

        return level
    }


    mutating func reset() {
        level = 0
        runningPeak = minPeak
    }
}
