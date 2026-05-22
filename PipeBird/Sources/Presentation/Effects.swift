// Effects.swift — UNVERIFIED. Programmatic, asset-free presentation: a floating score pop and a crash
// "poof" of scattering bits (avoids needing a bundled .sks particle file). Presentation only.

#if canImport(SpriteKit)
    import SpriteKit
    #if canImport(UIKit)
        import UIKit
    #endif

    enum Effects {
        static func scorePop(in scene: SKScene, at point: CGPoint, score: Int) {
            let label = SKLabelNode(text: "\(score)")
            label.fontName = "AvenirNext-Bold"
            label.fontSize = 28
            label.fontColor = .white
            label.position = CGPoint(x: point.x, y: point.y + 24)
            label.zPosition = 100
            scene.addChild(label)
            label.run(.sequence([
                .group([
                    .moveBy(x: 0, y: 40, duration: 0.6),
                    .fadeOut(withDuration: 0.6)
                ]),
                .removeFromParent()
            ]))
        }

        static func crashPoof(in scene: SKScene, at point: CGPoint) {
            for _ in 0 ..< 12 {
                let bit = SKShapeNode(circleOfRadius: 3)
                bit.fillColor = SKColor(white: 1.0, alpha: 0.9)
                bit.strokeColor = .clear
                bit.position = point
                bit.zPosition = 100
                scene.addChild(bit)
                let dx = CGFloat.random(in: -60 ... 60)
                let dy = CGFloat.random(in: -60 ... 60)
                bit.run(.sequence([
                    .group([
                        .moveBy(x: dx, y: dy, duration: 0.5),
                        .fadeOut(withDuration: 0.5)
                    ]),
                    .removeFromParent()
                ]))
            }
        }
    }

    enum Haptics {
        static func impact() {
            #if canImport(UIKit)
                guard FeatureFlags.hapticsEnabled else { return }
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            #endif
        }
    }
#endif
