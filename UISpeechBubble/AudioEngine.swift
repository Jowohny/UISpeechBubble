//
//  AudioEngine.swift
//  UISpeechBubble
//
//  Created by Johny Vu on 6/14/26.
//

import AVFoundation
import Accelerate
import Combine

final class AudioEngine: ObservableObject {

    /// Latest raw RMS amplitude, published on the main thread for SwiftUI.
    @Published private(set) var level: Double = 0

    private let engine = AVAudioEngine()
    private let lock = NSLock()
    private var _latestRMS: Double = 0
    private var isRunning = false

    /// Thread-safe accessor for the render loop (Unit 5 reads this each frame).
    var latestRMS: Double {
        lock.lock(); defer { lock.unlock() }
        return _latestRMS
    }

    // MARK: Lifecycle

    /// Configure the session, install the tap, and start capturing.
    /// Safe to call when already running (no-op) or without permission (fails into idle).
    func start() {
        guard !isRunning else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            // .measurement disables built-in processing for a cleaner level signal.
            try session.setCategory(.record, mode: .measurement, options: [])
            // Ask the hardware for a short input buffer to cut latency (the system
            // rounds to the nearest size it supports). ~5ms vs the ~23ms default.
            try session.setPreferredIOBufferDuration(0.005)
            try session.setActive(true)
        } catch {
            print("AudioEngine: session setup failed — \(error)")
            return
        }

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)

        // Guard against an invalid input format (e.g. no mic permission yet),
        // which would otherwise throw inside installTap.
        guard format.sampleRate > 0, format.channelCount > 0 else {
            print("AudioEngine: invalid input format — is mic permission granted?")
            return
        }

        // Smaller tap buffer = fresher RMS readings (≈5ms of audio vs ≈21ms default).
        input.installTap(onBus: 0, bufferSize: 256, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            let rms = AudioEngine.computeRMS(buffer)
            self.lock.lock(); self._latestRMS = rms; self.lock.unlock()
            DispatchQueue.main.async { self.level = rms }
        }

        engine.prepare()
        do {
            try engine.start()
            isRunning = true
            registerNotifications()
        } catch {
            print("AudioEngine: engine start failed — \(error)")
            input.removeTap(onBus: 0)
            isRunning = false
        }
    }

    /// Stop capturing and settle back to silence.
    func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false
        clearLevel()
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    /// Reset the loudness to zero so the sphere returns to its idle state.
    private func clearLevel() {
        lock.lock(); _latestRMS = 0; lock.unlock()
        DispatchQueue.main.async { self.level = 0 }
    }

    // MARK: RMS

    /// Root-mean-square amplitude of a buffer's first channel, via Accelerate.
    private static func computeRMS(_ buffer: AVAudioPCMBuffer) -> Double {
        guard let channel = buffer.floatChannelData, buffer.frameLength > 0 else { return 0 }
        var rms: Float = 0
        vDSP_rmsqv(channel[0], 1, &rms, vDSP_Length(buffer.frameLength))
        return rms.isFinite ? Double(rms) : 0
    }

    // MARK: Interruptions & route changes

    private func registerNotifications() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(handleInterruption(_:)),
                           name: AVAudioSession.interruptionNotification, object: nil)
        center.addObserver(self, selector: #selector(handleRouteChange(_:)),
                           name: AVAudioSession.routeChangeNotification, object: nil)
    }

    @objc private func handleInterruption(_ note: Notification) {
        guard let info = note.userInfo,
              let raw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }

        switch type {
        case .began:
            // System took the audio session (e.g. phone call); pause cleanly and
            // clear the last level so the sphere eases back to idle instead of
            // freezing mid-reaction.
            engine.pause()
            clearLevel()
        case .ended:
            // Resume only if the system says we may.
            if let optRaw = info[AVAudioSessionInterruptionOptionKey] as? UInt,
               AVAudioSession.InterruptionOptions(rawValue: optRaw).contains(.shouldResume) {
                try? AVAudioSession.sharedInstance().setActive(true)
                try? engine.start()
            }
        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(_ note: Notification) {
        // On a route change (headphones in/out) restart the engine if it stalled.
        guard isRunning, !engine.isRunning else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        try? engine.start()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
