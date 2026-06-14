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

    var level: CGFloat = 0

    private var points: [SIMD3<Float>] = []

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
        for i in 0..<n {
            let y = Double(i) * offset - 1 + offset / 2
            let r = sqrt(max(0, 1 - y * y))
            let phi = Double(i) * increment
            points.append(SIMD3<Float>(Float(cos(phi) * r),
                                       Float(y),
                                       Float(sin(phi) * r)))
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

        let breathing = 0.5 + 0.5 * sin(elapsed + 15)
        let drive = max(level, CGFloat(breathing) * 0.12)

        rotationY += CGFloat(dt) * 0.5
        let tilt: CGFloat = 0.45
        let cosY = cos(rotationY), sinY = sin(rotationY)
        let cosX = cos(tilt), sinX = sin(tilt)

        let baseRadius = min(size.width, size.height) * 0.32
        let radius = baseRadius * (1 + drive * 0.26)
        let perspective: CGFloat = 3.0

        for i in 0..<nodes.count {
            let p = points[i]
            var x = CGFloat(p.x), y = CGFloat(p.y), z = CGFloat(p.z)
 
            let scatter = 1 + drive * 0.16 *
                CGFloat(sin(Double(p.x) * 8 + Double(p.y) * 6 + elapsed * 6))
            x *= scatter; y *= scatter; z *= scatter

            let x1 = x * cosY - z * sinY
            let z1 = x * sinY + z * cosY
            let y1 = y * cosX - z1 * sinX
            let z2 = y * sinX + z1 * cosX

            let depth = (z2 + 1) / 2
            let persp = perspective / (perspective - z2)

            let node = nodes[i]
            node.position = CGPoint(x: x1 * radius * persp, y: y1 * radius * persp)
            node.zPosition = depth
            node.setScale((0.20 + depth * 0.48) * (0.9 + drive * 0.5))
            node.alpha = 0.07 + 0.75 * depth * depth
        }
    }
}
