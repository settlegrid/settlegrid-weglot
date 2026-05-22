// Core value types (SPEC §6.5–§6.7). Pure data; no behavior, no Foundation.

public struct Pipe: Equatable, Identifiable {
    public let id: Int
    public var x: Double // left edge (decreasing over time)
    public var gapCenterY: Double // locked at spawn
    public var gapHeight: Double // locked at spawn
    public var scored: Bool

    public init(id: Int, x: Double, gapCenterY: Double, gapHeight: Double, scored: Bool) {
        self.id = id
        self.x = x
        self.gapCenterY = gapCenterY
        self.gapHeight = gapHeight
        self.scored = scored
    }
}

public enum Status: Equatable { case ready, playing, crashed }
public enum Mode: Equatable { case good, evil }
public enum CrashReason: Equatable { case pipeBody, floor, ceiling }

public enum GameEvent: Equatable {
    case spawned(pipeID: Int)
    case pipePassed(score: Int)
    case crashed(CrashReason)
}

public struct Input: Equatable {
    public var targetGapY: Double
    public init(targetGapY: Double) {
        self.targetGapY = targetGapY
    }
}

public struct GameState: Equatable {
    public var status: Status
    public var mode: Mode
    public var birdY: Double
    public var birdVY: Double
    public var pipes: [Pipe]
    public var score: Int
    public var elapsed: Double
    public var spawnAccumulator: Double
    public var nextPipeID: Int

    /// Uses the synthesized internal memberwise init; tests build states via this factory plus
    /// direct field assignment (all fields are public var), so no public init is exposed (audit I5).
    public static func initial(config: GameConfig) -> GameState {
        GameState(
            status: .ready,
            mode: .good,
            birdY: config.height / 2,
            birdVY: 0,
            pipes: [],
            score: 0,
            elapsed: 0,
            spawnAccumulator: 0,
            nextPipeID: 0
        )
    }
}
