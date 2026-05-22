// GameConfig — the single source of tuning constants (SPEC §5, §6.3). Defaults match the §5 table.

public struct GameConfig: Equatable {
    public var width: Double
    public var height: Double
    public var birdX: Double
    public var birdRadius: Double
    public var pipeWidth: Double
    public var pipeSpacing: Double
    public var baseGapHeight: Double
    public var minGapHeight: Double
    public var gapShrinkPerScore: Double
    public var baseScrollSpeed: Double
    public var scrollSpeedPerScore: Double
    public var maxScrollSpeed: Double
    public var stiffness: Double
    public var damping: Double
    public var maxBirdSpeed: Double
    public var fixedDt: Double
    public var maxRealDelta: Double
    public var seed: UInt64

    public init(
        width: Double = 400,
        height: Double = 700,
        birdX: Double = 120,
        birdRadius: Double = 14,
        pipeWidth: Double = 60,
        pipeSpacing: Double = 240,
        baseGapHeight: Double = 220,
        minGapHeight: Double = 120,
        gapShrinkPerScore: Double = 2.0,
        baseScrollSpeed: Double = 140,
        scrollSpeedPerScore: Double = 4.0,
        maxScrollSpeed: Double = 360,
        stiffness: Double = 28.0,
        damping: Double = 6.0,
        maxBirdSpeed: Double = 520,
        fixedDt: Double = 1.0 / 120.0,
        maxRealDelta: Double = 0.25,
        seed: UInt64 = 0xA5A5_5A5A_C0DE_F00D
    ) {
        self.width = width
        self.height = height
        self.birdX = birdX
        self.birdRadius = birdRadius
        self.pipeWidth = pipeWidth
        self.pipeSpacing = pipeSpacing
        self.baseGapHeight = baseGapHeight
        self.minGapHeight = minGapHeight
        self.gapShrinkPerScore = gapShrinkPerScore
        self.baseScrollSpeed = baseScrollSpeed
        self.scrollSpeedPerScore = scrollSpeedPerScore
        self.maxScrollSpeed = maxScrollSpeed
        self.stiffness = stiffness
        self.damping = damping
        self.maxBirdSpeed = maxBirdSpeed
        self.fixedDt = fixedDt
        self.maxRealDelta = maxRealDelta
        self.seed = seed
    }

    public static let standard = GameConfig()
}
