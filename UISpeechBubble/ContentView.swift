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

    /// The two top-level screens the segmented picker switches between.
    private enum Screen { case sphere, chat }

    @State private var scene = DotSphereScene()
    @State private var screen = Screen.sphere

    @StateObject private var audio = AudioEngine()

    // Owns the on-device model session for the chat screen.
    @StateObject private var chatEngine = ChatEngine()

    // Tracks mic permission and decides which screen to show.
    @StateObject private var permission = MicPermission()

    // Lets us notice when the app returns to the foreground, so we can re-check
    // permission (the user may have toggled the mic in Settings while away).
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch screen {
            case .sphere:
                sphereScreen
            case .chat:
                ChatView(engine: chatEngine)
            }
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        // Screen switcher pinned to the top; the reaction picker tucks in beneath it
        // (sphere screen only, once the mic is on). The sphere bleeds behind both.
        .safeAreaInset(edge: .top) {
            VStack(spacing: 8) {
                Picker("Screen", selection: $screen) {
                    Text("Sphere").tag(Screen.sphere)
                    Text("Chat")
                        .foregroundStyle(.white)
                        .tag(Screen.chat)
                }
                .pickerStyle(.segmented)

                if screen == .sphere && permission.status == .granted {
                    ReactionPicker(scene: scene)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
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
        // Manage capture across the app lifecycle.
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                // Coming back to the foreground: the user may have changed the
                // mic in Settings, so re-check, then resume capture if allowed.
                permission.refresh()
                if permission.status == .granted { audio.start() }
            case .background:
                // Free the mic while we're not on screen; the sphere falls back
                // to its idle rotation until we return.
                audio.stop()
            case .inactive:
                break   // transient (e.g. Control Center) — leave capture as-is
            @unknown default:
                break
            }
        }
    }

    /// The dot sphere plus its mic-permission overlays. Chat has no need for the mic,
    /// so the permission screens stay scoped to this screen.
    private var sphereScreen: some View {
        SpriteView(scene: scene, options: [.ignoresSiblingOrder])
            .ignoresSafeArea()
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
