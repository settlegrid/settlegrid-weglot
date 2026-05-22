// PipeNode.swift — UNVERIFIED. A pipe pair (top + bottom solid rects) drawn from a core `Pipe`.
// Geometry matches SPEC §3 exactly: bottom rect y ∈ [0, gapBottom], top rect y ∈ [gapTop, height],
// both across x ∈ [pipe.x, pipe.x + pipeWidth]. The right edge is computed here, never stored on Pipe.

#if canImport(SpriteKit)
    import PipeBirdCore
    import SpriteKit

    final class PipeNode: SKNode {
        private let top = SKShapeNode()
        private let bottom = SKShapeNode()

        override init() {
            super.init()
            for part in [top, bottom] {
                part.fillColor = SKColor(red: 0.30, green: 0.70, blue: 0.32, alpha: 1.0)
                part.strokeColor = SKColor(white: 0.0, alpha: 0.18)
                part.lineWidth = 2
                addChild(part)
            }
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("use init()")
        }

        /// Rebuild the rects each frame from absolute world coordinates (no node translation needed).
        func update(pipe: Pipe, config: GameConfig) {
            let gapTop = pipe.gapCenterY + pipe.gapHeight / 2
            let gapBottom = pipe.gapCenterY - pipe.gapHeight / 2
            top.path = CGPath(
                rect: CGRect(x: pipe.x, y: gapTop, width: config.pipeWidth, height: config.height - gapTop),
                transform: nil
            )
            bottom.path = CGPath(
                rect: CGRect(x: pipe.x, y: 0, width: config.pipeWidth, height: gapBottom),
                transform: nil
            )
        }
    }
#endif
