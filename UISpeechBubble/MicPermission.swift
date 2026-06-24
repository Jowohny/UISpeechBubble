//
//  MicPermission.swift
//  UISpeechBubble
//
//  Tracks whether we're allowed to use the microphone, and asks for access.
//  Wraps Apple's AVAudioApplication permission API in a simple 3-state enum the
//  UI can switch on. SwiftUI watches `status` and shows the right screen.
//

import AVFoundation
import Combine

@MainActor
final class MicPermission: ObservableObject {

    /// The three situations the UI cares about.
    enum Status { case undetermined, granted, denied }

    @Published private(set) var status: Status = .undetermined

    init() {
        refresh()
    }

    /// Read the current system permission. Call this on launch and whenever the
    /// app returns to the foreground (the user may have changed it in Settings).
    func refresh() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:      status = .granted
        case .denied:       status = .denied
        case .undetermined: status = .undetermined
        @unknown default:   status = .denied
        }
    }

    /// Show the one-time system permission prompt, then record the answer.
    /// iOS only ever shows this dialog once; after that this returns the stored
    /// choice without prompting again.
    func request() {
        AVAudioApplication.requestRecordPermission { granted in
            // The callback arrives on a background thread; hop to the main actor
            // to update the published state safely.
            Task { @MainActor in
                self.status = granted ? .granted : .denied
            }
        }
    }
}
