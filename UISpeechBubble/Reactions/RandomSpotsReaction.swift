//
//  RandomSpotsReaction.swift
//  UISpeechBubble
//
// Created by Johny Vu on 6/20/26
//

import simd
import Foundation

struct RandomSpotsReaction: SphereReaction {

    var strength: Double = 0.5

    func deform(point p: SIMD3<Float>, random: Float,
                level: Double, drive: Double, time: TimeInterval) -> SIMD3<Float> {
        let x = Double(p.x), y = Double(p.y), z = Double(p.z), t = time

        let field = (sin(x * 3.3 + t * 1.7)
                   + sin(y * 4.1 - t * 1.3)
                   + sin(z * 3.7 + t * 2.1)
                   + sin((x + y + z) * 2.5 - t * 1.1)) / 4

        let d = 1 + level * strength * field
        return p * Float(d)
    }
}
