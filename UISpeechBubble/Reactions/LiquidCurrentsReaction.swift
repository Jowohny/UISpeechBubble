//
//  LiquidCurrentsReaction.swift
//  UISpeechBubble
//
//  Created by Johny Vu on 6/20/26
//
//  Liquid currents — organic eddies swirl across the surface like marbled mercury.
//  Dots slide sideways (around the vertical axis) by an amount that varies from
//  region to region and oscillates over time, so bands sway and reverse instead of
//  spinning rigidly. Louder = stronger currents.
//

import simd
import Foundation

struct LiquidCurrentsReaction: SphereReaction {

    /// Strength of the swirl at full volume (in radians of twist).
    var strength: Double = 1.5

    func deform(point p: SIMD3<Float>, random: Float, level: Double, drive: Double, time: TimeInterval) -> SIMD3<Float> {
        let x = Double(p.x), y = Double(p.y), z = Double(p.z), t = time

        // Twist angle around the vertical (Y) axis. It depends on the dot's
        // latitude (y) and longitude (x) AND wobbles in time, so neighbouring
        // bands rotate by different, shifting amounts — that mismatch is what reads
        // as flowing liquid rather than a solid spin. Rests at silence (uses level).
        let angle = level * strength * sin(y * 4 + t * 1.5) + level * 0.4 * sin(x * 3 - t * 1.1)
        let ca = cos(angle), sa = sin(angle)
        
        // Rotate only x and z (around the vertical axis); y is untouched, so dots
        // flow sideways across the surface instead of in/out.
        return SIMD3<Float>(Float(x * ca - z * sa), Float(y), Float(x * sa + z * ca))
    }
}
