//
//  ChatView.swift
//  UISpeechBubble
//
//  Created by Johny Vu on 7/11/26.
//
//  The chat screen: a transcript plus an input bar, talking to the on-device model
//  through ChatEngine. Deliberately dumb — all model logic lives in ChatEngine. Its
//  first job is to prove the model actually responds on this hardware.

import SwiftUI

struct ChatView: View {

    @ObservedObject var engine: ChatEngine

    /// The text being typed. Local to the view — it becomes a ChatMessage on send.
    @State private var draft = ""

    // Reuse the sphere's cool/warm palette so the two screens feel like one app.
    private let cool = Color(red: 0.55, green: 0.68, blue: 1.0)
    private let warm = Color(red: 1.0, green: 0.50, blue: 0.20)

    /// When the model can't run, this is the reason to show; nil means it's ready.
    private var unavailableReason: String? {
        if case .unavailable(let reason) = engine.availability { return reason }
        return nil
    }

    private var canSend: Bool {
        unavailableReason == nil
            && !engine.isResponding
            && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            if let reason = unavailableReason {
                banner(reason)
            }

            transcript

            inputBar
        }
        .background(Color.black.ignoresSafeArea())
    }

    // MARK: Transcript

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if engine.messages.isEmpty && unavailableReason == nil {
                        Text("Say hello to the on-device model.")
                            .foregroundStyle(.white.opacity(0.4))
                            .padding(.top, 40)
                    }
                    ForEach(engine.messages) { message in
                        bubble(for: message).id(message.id)
                    }
                    if engine.isResponding {
                        HStack {
                            ProgressView().tint(cool)
                            Spacer(minLength: 40)
                        }
                        .id(Self.spinnerID)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            // Keep the newest line in view as the conversation grows.
            .onChange(of: engine.messages.count) { _, _ in scrollToEnd(proxy) }
            .onChange(of: engine.isResponding) { _, _ in scrollToEnd(proxy) }
        }
    }

    private func bubble(for message: ChatMessage) -> some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            Text(message.text)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background((message.role == .user ? warm : cool).opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }

    // MARK: Input

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Message", text: $draft, axis: .vertical)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .disabled(unavailableReason != nil)
                .onSubmit(send)

            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(canSend ? warm : .white.opacity(0.2))
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: Availability banner

    private func banner(_ reason: String) -> some View {
        Text(reason)
            .font(.footnote)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(warm.opacity(0.25))
    }

    // MARK: Actions

    private func send() {
        guard canSend else { return }
        let text = draft
        draft = ""
        Task { await engine.send(text) }
    }

    private func scrollToEnd(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            if engine.isResponding {
                proxy.scrollTo(Self.spinnerID, anchor: .bottom)
            } else if let last = engine.messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    private static let spinnerID = "responding-spinner"
}
