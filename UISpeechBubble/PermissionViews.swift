//
//  PermissionViews.swift
//  UISpeechBubble
//
//  The two microphone screens shown over the sphere: a friendly pre-prompt when
//  we haven't asked yet, and a recovery screen when access was denied. Both are
//  pure visuals — they take a closure for their button and own no logic.
//

import SwiftUI

/// Shown before we ask for the mic. Explaining *why* first means the user is far
/// more likely to allow it when the real iOS dialog appears (which only shows once).
struct MicPromptOverlay: View {
    let onEnable: () -> Void

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 14) {
                Text("Let your voice move the bubble")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Speak, sing, or play music — the dots react to sound in real time.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                Button(action: onEnable) {
                    Text("Enable Microphone")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 13)
                        .background(.white, in: Capsule())
                }
                .padding(.top, 4)
            }
            .padding(28)
            .padding(.bottom, 44)
        }
        .frame(maxWidth: 420)
        .ignoresSafeArea()
    }
}

/// Shown when the mic was denied. The sphere keeps rotating behind this so the
/// app still feels alive; the button deep-links to the app's Settings page —
/// the only place the user can re-enable the mic after denying.
struct MicDeniedOverlay: View {
    let onOpenSettings: () -> Void

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 14) {
                Image(systemName: "mic.slash.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white.opacity(0.85))
                Text("Microphone access is off")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Turn it on in Settings to let your voice move the bubble.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                Button(action: onOpenSettings) {
                    Text("Open Settings")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 13)
                        .background(.white, in: Capsule())
                }
                .padding(.top, 4)
            }
            .padding(28)
            .padding(.bottom, 44)
        }
        .frame(maxWidth: 420)
        .ignoresSafeArea()
    }
}
