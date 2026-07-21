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
            // The failure can arrive as a clean GenerationError enum or — as seen with a
            // missing model — as a bridged NSError wrapping a lower ModelManagerServices
            // error, where `localizedDescription` is the useless "…GenerationError error -1".
            // describe() digs out whichever is real. Raw error goes to the console too.
            print("ChatEngine send failed:", error)
            messages.append(ChatMessage(role: .assistant, text: "⚠️ \(ChatEngine.describe(error))"))
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

    /// Turn any error from `respond` into a human-readable line. The model layer throws two
    /// shapes: a clean `GenerationError` enum, or a bridged `NSError` (domain
    /// `FoundationModels.LanguageModelSession.GenerationError`, code -1) that wraps the real
    /// cause under `NSMultipleUnderlyingErrorsKey`. Handle both instead of trusting
    /// `localizedDescription`, which flattens the NSError shape to "error -1".
    private static func describe(_ error: Error) -> String {
        if let generationError = error as? LanguageModelSession.GenerationError {
            return describe(generationError)
        }
        // Descend to the deepest underlying error — that's where ModelManagerServices puts
        // the actual reason (e.g. code 1026 when the on-device model isn't installed).
        var root = error as NSError
        while let deeper = root.underlyingErrors.last { root = deeper as NSError }
        if root.domain == "ModelManagerServices.ModelManagerError" {
            return "The on-device model isn't installed on this device yet. Turn on Apple "
                + "Intelligence and let the model finish downloading, then try again. "
                + "(\(root.domain) \(root.code))"
        }
        return "\(root.domain) \(root.code)"
    }

    /// Turn a GenerationError into a human-readable line. Each case carries a `Context`
    /// whose `debugDescription` holds the underlying detail we'd otherwise lose to the
    /// generic "error -1" bridge.
    private static func describe(_ error: LanguageModelSession.GenerationError) -> String {
        switch error {
        case .assetsUnavailable(let c):
            return "The on-device model's assets aren't ready yet — Apple Intelligence may still be downloading. \(c.debugDescription)"
        case .exceededContextWindowSize(let c):
            return "This conversation is too long for the model's context window. \(c.debugDescription)"
        case .guardrailViolation(let c):
            return "The request tripped the safety guardrail. \(c.debugDescription)"
        case .unsupportedGuide(let c):
            return "Unsupported generation guide. \(c.debugDescription)"
        case .unsupportedLanguageOrLocale(let c):
            return "Unsupported language or locale. \(c.debugDescription)"
        case .decodingFailure(let c):
            return "The model's output couldn't be decoded. \(c.debugDescription)"
        case .rateLimited(let c):
            return "Too many requests too quickly. \(c.debugDescription)"
        case .concurrentRequests(let c):
            return "The session is already handling a request. \(c.debugDescription)"
        case .refusal(_, let c):
            return "The model declined to answer. \(c.debugDescription)"
        @unknown default:
            return error.failureReason ?? error.localizedDescription
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
