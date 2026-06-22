//
//  ReactionKind.swift
//  UISpeechBubble
//
//  Created by Johny Vu on 6/21/26
//
//  A registry of the available sphere reactions. One enum case per reaction,
//  each knowing its display name and how to build a fresh instance. This gives us
//  a single list to drive the picker menu, and one place to add future reactions.
//

import Foundation

enum ReactionKind: String, CaseIterable, Identifiable {
    case randomSpots    = "Random Spots"
    case dissolveCloud  = "Dissolve Cloud"
    case ferrofluid     = "Ferrofluid"
    case liquidCurrents = "Liquid Currents"

    /// `Identifiable` conformance lets SwiftUI's ForEach/Picker iterate these.
    var id: String { rawValue }

    /// Human-readable label for the menu (the raw value doubles as the title).
    var title: String { rawValue }

    /// Build a fresh reaction instance for this case. Each reaction is a small
    /// value type, so making a new one when the selection changes is cheap.
    func make() -> SphereReaction {
        switch self {
        case .randomSpots:    return RandomSpotsReaction()
        case .dissolveCloud:  return DissolveCloudReaction()
        case .ferrofluid:     return FerrofluidReaction()
        case .liquidCurrents: return LiquidCurrentsReaction()
        }
    }
}
