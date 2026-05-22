// RNGTests.swift  — STUB (agent fills bodies; keep the assertions described in each comment)
// PROPERTY: DeterministicRNG (SplitMix64) is reproducible and in-range. Trap: a "random" generator
// that isn't actually seeded/reproducible, or nextDouble that escapes its range.
import XCTest
@testable import PipeBirdCore

final class RNGTests: XCTestCase {

    /// Two DeterministicRNG(seed: s) produce identical first-100 `next()` sequences.
    func testSameSeedSameSequence() {
        XCTFail("STUB: assert two DeterministicRNG(seed:) instances yield identical next() x100")
    }

    /// nextDouble(in:) stays within the closed range over 10k draws; never NaN/Inf.
    func testNextDoubleInRange() {
        XCTFail("STUB: assert 10k nextDouble(in: lo...hi) values are finite and within [lo, hi]")
    }
}
