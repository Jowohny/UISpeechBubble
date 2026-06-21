//
//  SphereReaction.swift
//  UISpeechBubble
//
// Created by Johny Vu 6/20/26
//

import simd
import Foundation

protocol SphereReaction {
    func deform(point: SIMD3<Float>, random: Float,
                level: Double, drive: Double, time: TimeInterval) -> SIMD3<Float>
}
