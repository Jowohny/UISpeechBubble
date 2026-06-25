//
//  DissolveCloudReaction.swift
//  UISpeechBubble
//
//  Created by Johny Vu on 6/20/26
//
//  Dissolve cloud — on peaks each dot flies out to its own distance, melting the
//  crisp sphere into a glowing cloud, then snapping back to a sphere when quiet.
//

import simd
import Foundation

struct DissolveCloudReaction: SphereReaction {

    /// How far the cloud spreads at full volume. Bigger = looser, wider cloud.
    var strength: Double = 0.4

    func deform(point p: SIMD3<Float>, random: Float, level: Double, drive: Double, time: TimeInterval) -> SIMD3<Float> {
        let rnd = Double(random)

        // Each dot shimmers on its own phase (offset by its random value), so the
        // cloud churns and twinkles instead of pulsing as one solid shell.
        let wobble = 0.5 + 0.5 * sin(time * 2.0 + rnd * 9)

        // Outward distance is unique per dot: the random value sets how far this
        // particular dot flings out. 0.15 keeps every dot moving a little so the
        // whole surface lifts off, not just some dots.
        let d = 1 + level * (0.15 + strength * rnd) * wobble
        
        return p * Float(d)
    }
}
