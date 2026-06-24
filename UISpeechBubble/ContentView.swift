//
//  ContentView.swift
//  UISpeechBubble
//
//  Created by Johny Vu on 6/12/26.
//

import SwiftUI
import SpriteKit
import UIKit

struct ContentView: View {

    @State private var scene = DotSphereScene()

    @StateObject private var audio = AudioEngine()

    // Tracks mic permission and decides which screen to show.
    @StateObject private var permission = MicPermission()

    // Lets us notice when the app returns to the foreground, so we can re-check
    // permission (the user may have toggled the mic in Settings while away).
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        // The reaction picker only makes sense once the mic is on.
        .overlay(alignment: .top) {
            if permission.status == .granted {
                ReactionPicker(scene: scene)
                    .padding(.top, 12)
            }
        }
        // The permission screens, layered over the (always-rotating) sphere.
        .overlay {
            switch permission.status {
            case .undetermined:
                MicPromptOverlay { permission.request() }
            case .denied:
                MicDeniedOverlay(onOpenSettings: openSettings)
            case .granted:
                EmptyView()
            }
        }
        .onAppear {
            scene.micEngine = audio
            // If access was already granted on a previous launch, start now —
            // onChange below won't fire because the value didn't change.
            if permission.status == .granted { audio.start() }
        }
        // One place that starts/stops capture as permission flips.
        .onChange(of: permission.status) { _, status in
            if status == .granted { audio.start() } else { audio.stop() }
        }
        // Re-check permission whenever we come back to the foreground.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { permission.refresh() }
        }
    }

    /// Deep-link to this app's page in the Settings app.
    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    ContentView()
}
