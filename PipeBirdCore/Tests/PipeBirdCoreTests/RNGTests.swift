// RNGTests.swift
// PROPERTY: DeterministicRNG (SplitMix64) is reproducible and in-range. Trap: a "random" generator
// that isn't actually seeded/reproducible, or a nextDouble that escapes its closed range or yields
// NaN/Inf. AUDITOR ORACLE: one rng instance per sequence; same seed ⇒ identical streams.
@testable import PipeBirdCore
import XCTest

final class RNGTests: XCTestCase {
    /// Two DeterministicRNG(seed:) produce identical first-100 next() sequences; different seeds diverge.
    func testSameSeedSameSequence() {
        var a = DeterministicRNG(seed: 0xDEAD_BEEF)
        var b = DeterministicRNG(seed: 0xDEAD_BEEF)
        for i in 0 ..< 100 {
            XCTAssertEqual(a.next(), b.next(), "same seed must reproduce the stream (draw \(i))")
        }

        var c = DeterministicRNG(seed: 0xDEAD_BEEF)
        var d = DeterministicRNG(seed: 0xDEAD_BEEE)
        var anyDifferent = false
        for _ in 0 ..< 100 where c.next() != d.next() {
            anyDifferent = true
        }
        XCTAssertTrue(anyDifferent, "different seeds must not yield identical sequences")
    }

    /// nextDouble(in:) stays within the closed range over 10k draws and is always finite.
    func testNextDoubleInRange() {
        var rng = DeterministicRNG(seed: 0x1234_5678_9ABC_DEF0)
        let lo = -5.0
        let hi = 12.5
        for _ in 0 ..< 10000 {
            let v = rng.nextDouble(in: lo ... hi)
            XCTAssertTrue(v.isFinite, "draw must be finite")
            XCTAssertGreaterThanOrEqual(v, lo)
            XCTAssertLessThanOrEqual(v, hi)
        }
    }
}
