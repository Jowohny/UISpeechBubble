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

    @Published private(set) var level: Double = 0

    private let engine = AVAudioEngine()
    private let lock = NSLock()
    private var _latestRMS: Double = 0
    private var isRunning = false

    var latestRMS: Double {
        lock.lock(); defer { lock.unlock() }
        return _latestRMS
    }

    func start() {
        guard !isRunning else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [])
            try session.setActive(true)
        } catch {
            print("AudioEngine: session setup failed — \(error)")
            return
        }

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)

        guard format.sampleRate > 0, format.channelCount > 0 else {
            print("AudioEngine: invalid input format — is mic permission granted?")
            return
        }

        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
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

    func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false
        lock.lock(); _latestRMS = 0; lock.unlock()
        DispatchQueue.main.async { self.level = 0 }
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    private static func computeRMS(_ buffer: AVAudioPCMBuffer) -> Double {
        guard let channel = buffer.floatChannelData, buffer.frameLength > 0 else { return 0 }
        var rms: Float = 0
        vDSP_rmsqv(channel[0], 1, &rms, vDSP_Length(buffer.frameLength))
        return rms.isFinite ? Double(rms) : 0
    }

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
            engine.pause()
        case .ended:
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
        guard isRunning, !engine.isRunning else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        try? engine.start()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
