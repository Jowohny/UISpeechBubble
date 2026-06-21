//
//  LiquidCurrentsReaction.swift
//  UISpeechBubble
//
//  Created by Johny Vu on 6/20/26
//

import simd
import Foundation

struct LiquidCurrentsReaction: SphereReaction {

    var strength: Double = 1.5

    func deform(point p: SIMD3<Float>, random: Float,
                level: Double, drive: Double, time: TimeInterval) -> SIMD3<Float> {
        let x = Double(p.x), y = Double(p.y), z = Double(p.z), t = time

        let angle = level * strength * sin(y * 4 + t * 1.5) + level * 0.4 * sin(x * 3 - t * 1.1)
        let ca = cos(angle), sa = sin(angle)
        
        return SIMD3<Float>(Float(x * ca - z * sa), Float(y), Float(x * sa + z * ca))
    }
}
