//
//  FerrofluidReaction.swift
//  UISpeechBubble
//
//  Created by Johny Vu on 6/20/26
//
//  Ferrofluid spikes — sharp spikes erupt from the surface in a shifting pattern
//  on peaks (like magnetic-fluid art), then retract when quiet.
//

import simd
import Foundation

struct FerrofluidReaction: SphereReaction {

    /// How tall the spikes get at full volume.
    var strength: Double = 0.5
    /// Higher = more, finer spikes packed onto the surface.
    var frequency: Double = 9.0

    func deform(point p: SIMD3<Float>, random: Float, level: Double, drive: Double, time: TimeInterval) -> SIMD3<Float> {
        let x = Double(p.x), y = Double(p.y), z = Double(p.z), t = time, f = frequency

        // Multiply three drifting sine waves. A product is near zero unless ALL
        // three are large at once, which only happens at scattered points — so the
        // surface stays smooth except where spikes punch through.
        let s = sin(x * f + t * 0.6) * sin(y * f + t * 0.5) * sin(z * f - t * 0.4)

        // abs() makes every spike point outward; pow() sharpens the rounded bumps
        // into points (higher exponent = pointier, sparser spikes).
        let spike = pow(abs(s), 1.2)
        let d = 1 + level * strength * spike
        
        return p * Float(d)
    }
}
