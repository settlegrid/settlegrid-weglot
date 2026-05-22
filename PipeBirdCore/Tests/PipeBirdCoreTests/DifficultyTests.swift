// DifficultyTests.swift — STUB
// PROPERTY: difficulty curves are monotonic, clamped, and overflow-safe. Trap: unclamped growth;
// Int overflow in the score term; off-by-one at score 0.
import XCTest
@testable import PipeBirdCore

final class DifficultyTests: XCTestCase {

    /// scrollSpeed non-decreasing in score; == maxScrollSpeed once capped; scrollSpeed(0) == baseScrollSpeed.
    func testScrollSpeedMonotonicCapped() {
        XCTFail("STUB: assert scrollSpeed(0)==base, non-decreasing, and equals maxScrollSpeed past the cap")
    }

    /// gapHeight non-increasing; floored at minGapHeight; gapHeight(0) == baseGapHeight.
    func testGapHeightMonotonicFloored() {
        XCTFail("STUB: assert gapHeight(0)==base, non-increasing, and floored at minGapHeight")
    }

    /// Extreme score (e.g. 10_000) → finite, clamped, no overflow/crash.
    func testExtremeScoreFiniteClamped() {
        XCTFail("STUB: assert scrollSpeed/gapHeight at score 10_000 are finite and at their caps")
    }
}
