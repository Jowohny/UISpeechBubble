//
//  RandomSpotsReaction.swift
//  UISpeechBubble
//
// Created by Johny Vu on 6/20/26
//
//  Random spots — smooth patches of the surface bulge outward and sink back at
//  roaming, random-feeling spots, so the sphere "simmers" while you talk.
//

import simd
import Foundation

struct RandomSpotsReaction: SphereReaction {

    /// How far the patches push out at full volume, as a fraction of the radius.
    /// Bigger = deeper bulges. Tweak this to taste.
    var strength: Double = 0.5

    func deform(point p: SIMD3<Float>, random: Float, level: Double, drive: Double, time: TimeInterval) -> SIMD3<Float> {
        let x = Double(p.x), y = Double(p.y), z = Double(p.z), t = time

        // Four sine waves at different frequencies and drift speeds, summed.
        // Because their periods don't line up, the combined "field" is lumpy and
        // never repeats cleanly — that's what makes the bulges look random rather
        // than a tidy grid. Dividing by 4 keeps the result in about -1...1.
        let field = (sin(x * 3.3 + t * 1.7) + sin(y * 4.1 - t * 1.3) + sin(z * 3.7 + t * 2.1) + sin((x + y + z) * 2.5 - t * 1.1)) / 4

        // Push each dot in/out along its own direction by the field, scaled by
        // loudness (so it's flat when silent).
        let d = 1 + level * strength * field
        
        return p * Float(d)
    }
}
