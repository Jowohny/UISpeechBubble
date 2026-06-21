//
//  FerrofluidReaction.swift
//  UISpeechBubble
//

import simd
import Foundation

struct FerrofluidReaction: SphereReaction {

    var strength: Double = 0.5
    var frequency: Double = 9.0

    func deform(point p: SIMD3<Float>, random: Float,
                level: Double, drive: Double, time: TimeInterval) -> SIMD3<Float> {
        let x = Double(p.x), y = Double(p.y), z = Double(p.z), t = time, f = frequency

        let s = sin(x * f + t * 0.6) * sin(y * f + t * 0.5) * sin(z * f - t * 0.4)
        let spike = pow(abs(s), 1.2)
        let d = 1 + level * strength * spike
        
        return p * Float(d)
    }
}
