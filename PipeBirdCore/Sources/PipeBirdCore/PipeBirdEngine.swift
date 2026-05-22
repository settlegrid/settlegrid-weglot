// PipeBirdEngine — pure simulation step + geometric queries (SPEC §6.8, §7). Stdlib only.

// swiftformat:disable unusedArguments
// The rng parameter on step() is intentionally threaded but UNCONSUMED in MUST scope (SPEC §6.8,
// audit I2). Keep it named `rng`; do not let the formatter rename it to `_`.

public enum PipeBirdEngine {
    /// Steering target = gap center of the nearest active pipe; height/2 if none. (SPEC §4.1)
    /// "Active" = right edge still ahead of the bird's trailing edge (birdX − birdRadius).
    public static func birdTargetY(state: GameState, config: GameConfig) -> Double {
        let threshold = config.birdX - config.birdRadius
        var nearestX = Double.greatestFiniteMagnitude
        var target = config.height / 2
        for pipe in state.pipes {
            let rightEdge = pipe.x + config.pipeWidth
            if rightEdge > threshold, pipe.x < nearestX {
                nearestX = pipe.x
                target = pipe.gapCenterY
            }
        }
        return target
    }

    /// First solid contact, checked floor → ceiling → pipe rects (SPEC §4.2). Inclusive rule.
    public static func collision(state: GameState, config: GameConfig) -> CrashReason? {
        let r = config.birdRadius
        let cx = config.birdX
        let cy = state.birdY

        if cy - r <= 0 { return .floor }
        if cy + r >= config.height { return .ceiling }

        for pipe in state.pipes {
            let left = pipe.x
            let right = pipe.x + config.pipeWidth
            let gapTop = pipe.gapCenterY + pipe.gapHeight / 2
            let gapBottom = pipe.gapCenterY - pipe.gapHeight / 2
            // Bottom solid rect: y ∈ [0, gapBottom]. Top solid rect: y ∈ [gapTop, height].
            if circleHitsRect(cx: cx, cy: cy, r: r, left: left, right: right, bottom: 0, top: gapBottom) {
                return .pipeBody
            }
            if circleHitsRect(
                cx: cx,
                cy: cy,
                r: r,
                left: left,
                right: right,
                bottom: gapTop,
                top: config.height
            ) {
                return .pipeBody
            }
        }
        return nil
    }

    /// Inclusive nearest-point circle-vs-rect test: contact at distance == r counts as a hit.
    private static func circleHitsRect(
        cx: Double, cy: Double, r: Double,
        left: Double, right: Double, bottom: Double, top: Double
    ) -> Bool {
        let nx = min(max(cx, left), right)
        let ny = min(max(cy, bottom), top)
        let dx = cx - nx
        let dy = cy - ny
        return dx * dx + dy * dy <= r * r
    }

    /// One fixed-dt simulation step in the canonical order (SPEC §7). The rng parameter is reserved
    /// (audit I2): in MUST scope the simulation is player-deterministic and step() does NOT consume it.
    public static func step(
        state: GameState, config: GameConfig,
        input: Input, rng: inout DeterministicRNG
    ) -> (GameState, [GameEvent]) {
        // 1. Inert outside .playing (.ready and .crashed are no-ops).
        if state.status != .playing { return (state, []) }

        var s = state
        var events: [GameEvent] = []
        let dt = config.fixedDt

        // 2. Elapsed.
        s.elapsed += dt

        // 3. Scroll every pipe left; advance the spawn accumulator by the same distance.
        let speed = Difficulty.scrollSpeed(score: s.score, config: config)
        let dx = speed * dt
        for i in s.pipes.indices {
            s.pipes[i].x -= dx
        }
        s.spawnAccumulator += dx

        // 4. Spawn on cadence (while, subtracting pipeSpacing to carry the remainder).
        while s.spawnAccumulator >= config.pipeSpacing {
            let gh = Difficulty.gapHeight(score: s.score, config: config)
            let half = gh / 2
            let centerY = min(max(input.targetGapY, half), config.height - half)
            s.pipes.append(Pipe(
                id: s.nextPipeID, x: config.width,
                gapCenterY: centerY, gapHeight: gh, scored: false
            ))
            events.append(.spawned(pipeID: s.nextPipeID))
            s.nextPipeID += 1
            s.spawnAccumulator -= config.pipeSpacing
        }

        // 5. Integrate the bird — underdamped spring, semi-implicit (symplectic) Euler (SPEC §4.1).
        let target = birdTargetY(state: s, config: config)
        let accel = config.stiffness * (target - s.birdY) - config.damping * s.birdVY
        var vy = s.birdVY + accel * dt
        vy = min(max(vy, -config.maxBirdSpeed), config.maxBirdSpeed)
        s.birdVY = vy
        s.birdY += vy * dt

        // 6. Score: one point per pipe fully cleared past birdX − birdRadius (audit F3 unifies the
        //    boundary with collision so a pipe cannot both score and crash in the same step).
        let scoreLine = config.birdX - config.birdRadius
        for i in s.pipes.indices where !s.pipes[i].scored && s.pipes[i].x + config.pipeWidth <= scoreLine {
            s.pipes[i].scored = true
            s.score += 1
            events.append(.pipePassed(score: s.score))
        }

        // 7. Collision → terminal crash; return before culling (culling is cosmetic, SPEC §7).
        if let reason = collision(state: s, config: config) {
            s.status = .crashed
            events.append(.crashed(reason))
            return (s, events)
        }

        // 8. Cull pipes fully off the left edge.
        s.pipes.removeAll { $0.x + config.pipeWidth < 0 }

        return (s, events)
    }
}
