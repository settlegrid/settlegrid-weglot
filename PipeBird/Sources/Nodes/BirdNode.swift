// BirdNode.swift — UNVERIFIED. The bird sprite: a body circle with googly eyes whose pupils lag the
// vertical velocity (Phase C feel) and a shocked face on crash. Pure presentation; reads no game state
// beyond what GameScene passes in.

#if canImport(SpriteKit)
    import SpriteKit

    final class BirdNode: SKNode {
        private let radius: Double
        private let body: SKShapeNode
        private let leftEye: SKShapeNode
        private let rightEye: SKShapeNode
        private let leftPupil: SKShapeNode
        private let rightPupil: SKShapeNode

        init(radius: Double) {
            self.radius = radius
            body = SKShapeNode(circleOfRadius: radius)
            let eyeR = radius * 0.30
            let pupilR = radius * 0.14
            leftEye = SKShapeNode(circleOfRadius: eyeR)
            rightEye = SKShapeNode(circleOfRadius: eyeR)
            leftPupil = SKShapeNode(circleOfRadius: pupilR)
            rightPupil = SKShapeNode(circleOfRadius: pupilR)
            super.init()

            body.fillColor = SKColor(red: 0.98, green: 0.82, blue: 0.16, alpha: 1.0)
            body.strokeColor = SKColor(white: 0.0, alpha: 0.15)
            addChild(body)

            for eye in [leftEye, rightEye] {
                eye.fillColor = .white
                eye.strokeColor = SKColor(white: 0, alpha: 0.2)
                addChild(eye)
            }
            for pupil in [leftPupil, rightPupil] {
                pupil.fillColor = .black
                pupil.strokeColor = .clear
                addChild(pupil)
            }
            leftEye.position = CGPoint(x: -radius * 0.35, y: radius * 0.35)
            rightEye.position = CGPoint(x: radius * 0.45, y: radius * 0.35)
            reset()
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("use init(radius:)")
        }

        func reset() {
            leftPupil.position = leftEye.position
            rightPupil.position = rightEye.position
            zRotation = 0
            body.fillColor = SKColor(red: 0.98, green: 0.82, blue: 0.16, alpha: 1.0)
        }

        /// Tilt the body and lag the pupils based on normalized vertical velocity.
        func applyVelocityTilt(_ vy: Double, maxSpeed: Double) {
            let t = max(-1.0, min(1.0, vy / maxSpeed))
            zRotation = CGFloat(t) * 0.4
            let lag = CGFloat(t) * radius * 0.18
            leftPupil.position = CGPoint(x: leftEye.position.x, y: leftEye.position.y + lag)
            rightPupil.position = CGPoint(x: rightEye.position.x, y: rightEye.position.y + lag)
        }

        /// Shocked face on crash: widen the eyes, redden the body slightly.
        func showShocked() {
            let widen = SKAction.scale(to: 1.3, duration: 0.08)
            leftEye.run(widen)
            rightEye.run(widen)
            body.fillColor = SKColor(red: 0.95, green: 0.55, blue: 0.20, alpha: 1.0)
        }
    }
#endif
