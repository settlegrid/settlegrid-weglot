// PipeBirdSimulation — the fixed-timestep driver the render shell calls (SPEC §6.9).

public struct PipeBirdSimulation {
    public private(set) var state: GameState
    public let config: GameConfig

    private var rng: DeterministicRNG
    private var timeAccumulator: Double

    public init(config: GameConfig = .standard) {
        self.config = config
        state = GameState.initial(config: config)
        rng = DeterministicRNG(seed: config.seed)
        timeAccumulator = 0
    }

    /// .ready → .playing only; a no-op from any other state (call reset() first).
    public mutating func start() {
        if state.status == .ready { state.status = .playing }
    }

    /// Back to initial(config) (status .ready); clear the accumulator and re-seed the rng.
    public mutating func reset() {
        state = GameState.initial(config: config)
        rng = DeterministicRNG(seed: config.seed)
        timeAccumulator = 0
    }

    /// Stored flag only; does not affect the simulation (mode-agnostic core, SPEC §4.3).
    public mutating func setMode(_ mode: Mode) {
        state.mode = mode
    }

    /// Clamp realDelta to maxRealDelta, accumulate, run floor(acc / fixedDt) fixed steps, and carry
    /// the sub-fixedDt remainder to the next call. Steps outside .playing are inert no-ops.
    public mutating func advance(realDelta: Double, input: Input) -> [GameEvent] {
        let clamped = min(realDelta, config.maxRealDelta)
        timeAccumulator += clamped
        var events: [GameEvent] = []
        while timeAccumulator >= config.fixedDt {
            let (next, evs) = PipeBirdEngine.step(state: state, config: config, input: input, rng: &rng)
            state = next
            events.append(contentsOf: evs)
            timeAccumulator -= config.fixedDt
        }
        return events
    }
}
