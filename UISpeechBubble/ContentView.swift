//
//  ContentView.swift
//  UISpeechBubble
//
//  Created by Johny Vu on 6/12/26.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    @State private var scene = DotSphereScene()

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
