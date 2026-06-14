//
//  ContentView.swift
//  UISpeechBubble
//
//  Created by Johny Vu on 6/12/26.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    private var scene: SKScene {
        let scene = SKScene(size: CGSize(width: 1, height: 1))
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .black
        return scene
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
    }
}

#Preview {
    ContentView()
}
