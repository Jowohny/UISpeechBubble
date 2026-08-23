//
//  TranscriptionEngine.swift
//  UISpeechBubble
//
//  Created by Johny Vu on 8/22/26.
//

import Speech
import AVFoundation
import Combine

@MainActor
final class TranscriptionEngine: ObservableObject {

    /// The text recognized so far. Updated live as the user speaks (partial
    /// results), then frozen as the final transcription when recording stops.
    @Published private(set) var transcript = ""

    /// True while we're actively listening and transcribing.
    @Published private(set) var isRecording = false

    /// Whether the user has granted speech-recognition permission. Distinct from
    /// mic permission (which AudioEngine/MicPermission handle) — Speech needs its
    /// own grant on top of the microphone.
    @Published private(set) var authorized = false

    /// The shared capture engine. We register as its buffer consumer while
    /// recording. Weak: ContentView owns both objects, so we don't co-own it.
    weak var audio: AudioEngine?

    private let recognizer = SFSpeechRecognizer()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    // MARK: Authorization

    /// Ask for speech-recognition permission. Cheap to call repeatedly — the
    /// system only prompts the first time. Call before the first start().
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            // The callback lands on an arbitrary queue; hop to main to publish.
            Task { @MainActor in
                self?.authorized = (status == .authorized)
            }
        }
    }

    // MARK: Recording

    /// Begin listening. Safe to call when already recording (no-op) or when we're
    /// not authorized / the recognizer is unavailable (fails quietly into idle).
    func start() {
        guard !isRecording, authorized else { return }
        guard let recognizer, recognizer.isAvailable, let audio else { return }

        // A fresh request per session; partial results give us live text, and
        // on-device keeps the audio off Apple's servers (matches the app's
        // privacy stance and works offline).
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        self.request = request

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            // Recognition callbacks arrive off the main actor; hop back to publish.
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }
                // Any error, or a final result, means this session is done.
                if error != nil || (result?.isFinal ?? false) {
                    self.finish()
                }
            }
        }

        // Route the mic tap's buffers into the recognizer. This closure runs on
        // the audio thread; append(_:) is safe to call there.
        audio.bufferConsumer = { [weak self] buffer in
            self?.request?.append(buffer)
        }

        isRecording = true
    }

    /// Stop listening. The recognizer flushes what it has, and the recognition
    /// callback's final result freezes the transcript. Idempotent.
    func stop() {
        guard isRecording else { return }
        request?.endAudio()          // tell the recognizer no more audio is coming
        finish()
    }

    /// Wipe the transcript so the next session starts from a blank panel.
    func clear() {
        transcript = ""
    }

    // MARK: Teardown

    /// Tear down the current session's resources and return to idle. Called both
    /// on manual stop() and when the recognizer ends on its own (final/error).
    private func finish() {
        audio?.bufferConsumer = nil  // stop feeding the tap into a dead request
        task?.cancel()
        task = nil
        request = nil
        isRecording = false
    }
}
