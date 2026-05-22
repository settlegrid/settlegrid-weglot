// Difficulty — pure, clamped, overflow-safe curves (SPEC §4.4, §6.4).
// Double(score) keeps the score term in floating point, so extreme scores clamp instead of trapping.

public enum Difficulty {
    public static func scrollSpeed(score: Int, config: GameConfig) -> Double {
        min(config.maxScrollSpeed, config.baseScrollSpeed + config.scrollSpeedPerScore * Double(score))
    }

    public static func gapHeight(score: Int, config: GameConfig) -> Double {
        max(config.minGapHeight, config.baseGapHeight - config.gapShrinkPerScore * Double(score))
    }
}
