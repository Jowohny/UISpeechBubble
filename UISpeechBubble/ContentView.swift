//
//  ContentView.swift
//  UISpeechBubble
//
//  Created by Johny Vu on 6/12/26.
//

import SwiftUI
import SpriteKit
import AVFoundation

struct ContentView: View {

    @State private var scene = DotSphereScene()

    @StateObject private var audio = AudioEngine()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onAppear {
            scene.micEngine = audio

            AVAudioApplication.requestRecordPermission { granted in
                if granted {
                    DispatchQueue.main.async { audio.start() }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
