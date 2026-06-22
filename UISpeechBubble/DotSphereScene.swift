//
//  DotSphereScene.swift
//  UISpeechBubble
//
//  Created by Johny Vu on 6/13/26.
//

import SpriteKit
import UIKit

final class DotSphereScene: SKScene {

    private let dotCount = 6000
    private let glowDiameter: CGFloat = 16

    weak var micEngine: AudioEngine?
    private var levelProcessor = LevelProcessor()

    /// The active sphere movement. Swap this one line to change the whole reaction:
    /// RandomSpotsReaction(), DissolveCloudReaction(), FerrofluidReaction(),
    /// or LiquidCurrentsReaction(). Each lives in its own file in Reactions/.
    var reaction: SphereReaction = RandomSpotsReaction()

    private var points: [SIMD3<Float>] = []
    /// Stable per-dot random value in 0...1 (parallel to `points`), for reactions
    /// that need per-dot variety such as dissolve.
    private var random: [Float] = []
    private var nodes: [SKSpriteNode] = []

    private var rotationY: CGFloat = 0
    private var elapsed: TimeInterval = 0
    private var lastUpdate: TimeInterval = 0

    override init() {
        super.init(size: CGSize(width: 1, height: 1))
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .black
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        if points.isEmpty {
            buildSphere()
        }
    }

    private func buildSphere() {
        let n = dotCount
        let offset = 2.0 / Double(n)
        let increment = Double.pi * (3.0 - sqrt(5.0))

        points.reserveCapacity(n)
        random.reserveCapacity(n)
        for i in 0..<n {
            let y = Double(i) * offset - 1 + offset / 2
            let r = sqrt(max(0, 1 - y * y))
            let phi = Double(i) * increment
            points.append(SIMD3<Float>(Float(cos(phi) * r),
                                       Float(y),
                                       Float(sin(phi) * r)))

            // A cheap, stable per-dot random in 0...1: take the fractional part of
            // a big multiple of a sine. Same value every frame for dot `i`.
            let h = sin(Double(i) * 12.9898) * 43758.5453
            random.append(Float(h - floor(h)))
        }

        let texture = Self.makeGlowTexture(diameter: glowDiameter)
        let baseColor = SKColor(red: 0.55, green: 0.68, blue: 1.0, alpha: 1.0)

        nodes.reserveCapacity(n)
        for _ in 0..<n {
            let node = SKSpriteNode(texture: texture)
            node.blendMode = .add
            node.color = baseColor
            node.colorBlendFactor = 1
            addChild(node)
            nodes.append(node)
        }
    }

    private static func makeGlowTexture(diameter: CGFloat) -> SKTexture {
        let size = CGSize(width: diameter, height: diameter)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cg = ctx.cgContext
            let colors = [
                UIColor(white: 1.0, alpha: 1.0).cgColor,
                UIColor(white: 1.0, alpha: 0.35).cgColor,
                UIColor(white: 1.0, alpha: 0.0).cgColor
            ] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: colors,
                                      locations: [0.0, 0.3, 1.0])!
            let center = CGPoint(x: diameter / 2, y: diameter / 2)
            cg.drawRadialGradient(gradient,
                                  startCenter: center, startRadius: 0,
                                  endCenter: center, endRadius: diameter / 2,
                                  options: [])
        }
        return SKTexture(image: image)
    }

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdate == 0 ? 1.0 / 60.0 : currentTime - lastUpdate
        lastUpdate = currentTime
        elapsed += dt

        let rawRMS = micEngine?.latestRMS ?? 0
        let level = CGFloat(levelProcessor.process(rawRMS: rawRMS, deltaTime: dt))

        let breathing = 0.5 + 0.5 * sin(elapsed * 0.8)
        let drive = max(level, CGFloat(breathing) * 0.12)

        let cool = (r: CGFloat(0.55), g: CGFloat(0.68), b: CGFloat(1.00))
        let warm = (r: CGFloat(1.00), g: CGFloat(0.50), b: CGFloat(0.20))
        let tint = SKColor(red:   cool.r + (warm.r - cool.r) * level,
                           green: cool.g + (warm.g - cool.g) * level,
                           blue:  cool.b + (warm.b - cool.b) * level,
                           alpha: 1.0)
        let brightnessBoost = 0.5 + 0.6 * level

        rotationY += CGFloat(dt) * 0.5
        let tilt: CGFloat = 0.45
        let cosY = cos(rotationY), sinY = sin(rotationY)
        let cosX = cos(tilt), sinX = sin(tilt)

        let baseRadius = min(size.width, size.height) * 0.32
        let radius = baseRadius * (1 + drive * 0.30)
        let perspective: CGFloat = 3.0

        for i in 0..<nodes.count {
            // Let the active reaction move this dot, then we rotate + project it.
            let moved = reaction.deform(point: points[i], random: random[i], level: Double(level), drive: Double(drive), time: elapsed)
            let x = CGFloat(moved.x), y = CGFloat(moved.y), z = CGFloat(moved.z)

            // Rotate around Y, then tilt around X.
            let x1 = x * cosY - z * sinY
            let z1 = x * sinY + z * cosY
            let y1 = y * cosX - z1 * sinX
            let z2 = y * sinX + z1 * cosX

            let depth = (z2 + 1) / 2
            let persp = perspective / (perspective - z2)

            let node = nodes[i]
            node.position = CGPoint(x: x1 * radius * persp, y: y1 * radius * persp)
            node.zPosition = depth
            node.color = tint
            node.setScale((0.20 + depth * 0.48) * (0.9 + drive * 0.6))
            node.alpha = (0.07 + 0.75 * depth * depth) * brightnessBoost
        }
    }
}
