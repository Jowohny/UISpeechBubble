//
//  ChatEngine.swift
//  UISpeechBubble
//
//  Created by Johny Vu on 7/11/26.
//
//  Wraps Apple's on-device Foundation Model so the views stay dumb — mirrors the
//  AudioEngine / MicPermission pattern. This is the smoke test that proves the model
//  loads and responds, and the reusable session we'll later use to drive the sphere.

import Combine
import Foundation
import FoundationModels

@MainActor
final class ChatEngine: ObservableObject {

    /// Whether the on-device model can run, resolved once at launch. When it can't, the
    /// UI shows `reason` so an unavailable model reads clearly instead of looking broken.
    enum Availability {
        case available
        case unavailable(reason: String)
    }

    /// The running transcript the chat screen renders.
    @Published private(set) var messages: [ChatMessage] = []
    /// True while the model is generating a reply — drives the input's disabled/spinner state.
    @Published private(set) var isResponding = false

    let availability: Availability

    /// One long-lived session so the model remembers earlier turns (multi-turn context).
    /// `var` so `reset()` can swap in a fresh session and forget the conversation.
    private var session = LanguageModelSession()

    init() {
        availability = ChatEngine.currentAvailability()
    }

    /// Send a user message and append the model's reply. Non-streaming: the reply lands
    /// all at once when generation finishes.
    func send(_ text: String) async {
        let prompt = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, !isResponding else { return }

        messages.append(ChatMessage(role: .user, text: prompt))
        isResponding = true
        defer { isResponding = false }

        do {
            let response = try await session.respond(to: prompt)
            messages.append(ChatMessage(role: .assistant, text: response.content))
        } catch {
            // Surface the failure in-line rather than crashing or silently dropping it.
            messages.append(ChatMessage(role: .assistant, text: "⚠️ \(error.localizedDescription)"))
        }
    }

    /// Start over: drop the transcript and the session's memory of it.
    func reset() {
        messages.removeAll()
        session = LanguageModelSession()
    }

    // MARK: Availability

    private static func currentAvailability() -> Availability {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available
        case .unavailable(let reason):
            return .unavailable(reason: describe(reason))
        }
    }

    private static func describe(_ reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible:
            return "This device doesn't support Apple Intelligence."
        case .appleIntelligenceNotEnabled:
            return "Turn on Apple Intelligence in Settings to chat with the model."
        case .modelNotReady:
            return "The on-device model is still downloading. Try again shortly."
        @unknown default:
            return "The on-device model is unavailable right now."
        }
    }
}
