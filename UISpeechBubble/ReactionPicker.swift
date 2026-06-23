//
//  ReactionPicker.swift
//  UISpeechBubble
//
//  A dropdown that lets the user switch which reaction the sphere is running.
//  Kept in its own small view so ContentView stays focused on layout.
//

import SwiftUI

struct ReactionPicker: View {
    /// The live scene to update. It's a class (reference type), so assigning onto
    /// it changes the running sphere directly — no rebuild needed.
    let scene: DotSphereScene

    /// The currently selected reaction. Starts on the scene's default so the
    /// label matches what's on screen.
    @State private var selected: ReactionKind = .randomSpots

    var body: some View {
        Menu {
            Picker("Reaction", selection: $selected) {
                ForEach(ReactionKind.allCases) { kind in
                    Text(kind.title).tag(kind)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(selected.title)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.white.opacity(0.12), in: Capsule())
        }
        // Apply the starting choice, and re-apply whenever the user picks one.
        .onAppear { scene.reaction = selected.make() }
        .onChange(of: selected) { _, kind in scene.reaction = kind.make() }
    }
}
