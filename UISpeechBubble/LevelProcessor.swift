//
//  LevelProcessor.swift
//  UISpeechBubble
//
// Created by Johny Vu on 6/13/26.

import Foundation

struct LevelProcessor {

    var riseInstance: Double = 0.02
    var fallInstance: Double = 0.09
    var noiseFloor: Double = 0.008
    var minPeak: Double = 0.03
    var peakDecayPerSecond: Double = 0.6

    private(set) var level: Double = 0
    private var runningPeak: Double

    init() {
        runningPeak = minPeak
    }

    @discardableResult
    mutating func process(rawRMS: Double, deltaTime: Double) -> Double {
        let dt = max(0, deltaTime)
        let rms = rawRMS.isFinite ? max(0, rawRMS) : 0

        let gated = rms <= noiseFloor ? 0 : rms

        let decay = pow(peakDecayPerSecond, dt)
        runningPeak = max(gated, runningPeak * decay)
        runningPeak = max(runningPeak, minPeak)
        let normalized = min(1, gated / runningPeak)

        let reactiveDirection = normalized > level ? riseInstance : fallInstance
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
