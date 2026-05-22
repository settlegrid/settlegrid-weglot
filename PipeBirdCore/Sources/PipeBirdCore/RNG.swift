// DeterministicRNG — SplitMix64. Stdlib only (no Foundation). SPEC §6.2, invariant §2.5.

public struct DeterministicRNG: RandomNumberGenerator {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    public mutating func nextDouble(in range: ClosedRange<Double>) -> Double {
        // Top 53 bits of next() → a uniform value in [0, 1), then scaled into the range.
        let unit = Double(next() >> 11) * (1.0 / 9_007_199_254_740_992.0) // 2^53
        return range.lowerBound + (range.upperBound - range.lowerBound) * unit
    }
}
