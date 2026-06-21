//
//  DissolveCloudReaction.swift
//  UISpeechBubble
//
//  Created by Johny Vu on 6/20/26
//

import simd
import Foundation

struct DissolveCloudReaction: SphereReaction {

    var strength: Double = 0.5

    func deform(point p: SIMD3<Float>, random: Float,
                level: Double, drive: Double, time: TimeInterval) -> SIMD3<Float> {
        let rnd = Double(random)

        let wobble = 0.5 + 0.5 * sin(time * 2.0 + rnd * 9)
        let d = 1 + level * (0.15 + strength * rnd) * wobble
        
        return p * Float(d)
    }
}
