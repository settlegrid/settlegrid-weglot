// GameScene.swift — UNVERIFIED. The render shell's driver. It owns the PipeBirdSimulation and, each
// frame: computes realDelta, reads the latest touch as targetGapY, calls simulation.advance, positions
// nodes from the returned state, and plays presentation for the returned events. NO GAMEPLAY LOGIC —
// movement/collision/scoring/spawning/difficulty all live in PipeBirdCore.

#if canImport(SpriteKit)
    import PipeBirdCore
    import SpriteKit
    #if canImport(UIKit)
        import UIKit
    #endif

    final class GameScene: SKScene {
        weak var model: GameModel?

        private let config = GameConfig.standard
        private var simulation = PipeBirdSimulation(config: .standard)
        private var lastUpdateTime: TimeInterval = 0
        private var targetGapY: Double = GameConfig.standard.height / 2

        private let bird = BirdNode(radius: GameConfig.standard.birdRadius)
        private let pipeLayer = SKNode()
        private var pipeNodes: [Int: PipeNode] = [:]
        private let floorNode = SKShapeNode()
        private let ghostGap = SKShapeNode()

        override init(size: CGSize) {
            super.init(size: size)
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("use init(size:)")
        }

        override func didMove(to _: SKView) {
            backgroundColor = SKColor(red: 0.53, green: 0.81, blue: 0.92, alpha: 1.0) // sky
            addChild(pipeLayer)

            floorNode.path = CGPath(rect: CGRect(x: 0, y: 0, width: config.width, height: 2), transform: nil)
            floorNode.fillColor = SKColor(red: 0.40, green: 0.28, blue: 0.15, alpha: 1.0)
            floorNode.strokeColor = .clear
            addChild(floorNode)

            ghostGap.strokeColor = SKColor.white.withAlphaComponent(0.5)
            ghostGap.lineWidth = 2
            ghostGap.isHidden = true
            addChild(ghostGap)

            addChild(bird)
            syncNodes(to: simulation.state)
        }

        /// Reset the frame clock so the first post-resume frame isn't a giant dt (hazard H2). The core's
        /// maxRealDelta clamp also caps it, but reset anyway.
        func resumeAfterBackground() {
            lastUpdateTime = 0
        }

        // MARK: - Input (render-only mapping; the engine clamps targetGapY authoritatively at spawn)

        private func updateTarget(from touches: Set<UITouch>) {
            guard let t = touches.first else { return }
            targetGapY = Double(t.location(in: self).y) // scene space == world space (PHASE_B_SPEC §1.1)
        }

        override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
            switch simulation.state.status {
            case .ready:
                simulation.start()
                lastUpdateTime = 0
            case .crashed:
                simulation.reset() // back to .ready, rng re-seeded, accumulator cleared
                simulation.start() // "tap to restart" = reset() then start() (SPEC §6.9)
                lastUpdateTime = 0
                bird.reset()
            case .playing:
                break
            }
            updateTarget(from: touches)
        }

        override func touchesMoved(_ touches: Set<UITouch>, with _: UIEvent?) {
            updateTarget(from: touches)
        }

        // MARK: - Fixed-timestep driver (hazard H2)

        override func update(_ currentTime: TimeInterval) {
            // Forward the (UI-chosen) mode each frame; setMode only flips a stored flag in the core.
            if let m = model?.mode, m != simulation.state.mode { simulation.setMode(m) }

            if lastUpdateTime == 0 {
                lastUpdateTime = currentTime // seed; skip the spike frame
                return
            }
            let realDelta = currentTime - lastUpdateTime
            lastUpdateTime = currentTime

            let events = simulation.advance(realDelta: realDelta, input: Input(targetGapY: targetGapY))
            syncNodes(to: simulation.state)
            present(events)
            model?.apply(status: simulation.state.status, score: simulation.state.score)
        }

        // MARK: - Render-only node sync

        private func syncNodes(to state: GameState) {
            bird.position = CGPoint(x: config.birdX, y: state.birdY)
            bird.applyVelocityTilt(state.birdVY, maxSpeed: config.maxBirdSpeed)

            var live = Set<Int>()
            for pipe in state.pipes {
                live.insert(pipe.id)
                let node: PipeNode
                if let existing = pipeNodes[pipe.id] {
                    node = existing
                } else {
                    node = PipeNode()
                    pipeNodes[pipe.id] = node
                    pipeLayer.addChild(node)
                }
                node.update(pipe: pipe, config: config)
            }
            for (id, node) in pipeNodes where !live.contains(id) {
                node.removeFromParent()
                pipeNodes[id] = nil
            }

            // Render-only "ghost gap" preview at the right edge, clamped for display only.
            let gh = Difficulty.gapHeight(score: state.score, config: config)
            let clamped = min(max(targetGapY, gh / 2), config.height - gh / 2)
            ghostGap.path = CGPath(
                rect: CGRect(
                    x: config.width - config.pipeWidth,
                    y: clamped - gh / 2,
                    width: config.pipeWidth,
                    height: gh
                ),
                transform: nil
            )
            ghostGap.isHidden = state.status != .playing
        }

        // MARK: - Event presentation (Phase C feel; presentation only)

        private func present(_ events: [GameEvent]) {
            for e in events {
                switch e {
                case .spawned:
                    AudioEngine.shared.play(.whoosh)
                case let .pipePassed(score):
                    AudioEngine.shared.play(.point)
                    Effects.scorePop(in: self, at: bird.position, score: score)
                case .crashed:
                    bird.showShocked()
                    Effects.crashPoof(in: self, at: bird.position)
                    AudioEngine.shared.play(.thud)
                    Haptics.impact()
                }
            }
        }
    }
#endif
