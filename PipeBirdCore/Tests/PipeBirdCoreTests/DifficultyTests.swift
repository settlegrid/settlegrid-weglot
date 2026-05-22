// DifficultyTests.swift
// PROPERTY: difficulty curves are monotonic, clamped, and overflow-safe. Trap: unclamped growth;
// Int overflow in the score term; off-by-one at score 0. AUDITOR ORACLE: scrollSpeed(0)==base,
// gapHeight(0)==base; both reach and hold their caps; Int.max must not trap.
@testable import PipeBirdCore
import XCTest

final class DifficultyTests: XCTestCase {
    private let c = GameConfig.standard

    /// scrollSpeed non-decreasing in score; scrollSpeed(0)==baseScrollSpeed; equals max once capped.
    func testScrollSpeedMonotonicCapped() {
        XCTAssertEqual(Difficulty.scrollSpeed(score: 0, config: c), c.baseScrollSpeed)
        var prev = -Double.infinity
        for s in 0 ... 200 {
            let v = Difficulty.scrollSpeed(score: s, config: c)
            XCTAssertGreaterThanOrEqual(v, prev, "scrollSpeed must be non-decreasing")
            XCTAssertLessThanOrEqual(v, c.maxScrollSpeed, "scrollSpeed must never exceed the cap")
            prev = v
        }
        XCTAssertEqual(Difficulty.scrollSpeed(score: 100_000, config: c), c.maxScrollSpeed)
    }

    /// gapHeight non-increasing; gapHeight(0)==baseGapHeight; floored at minGapHeight.
    func testGapHeightMonotonicFloored() {
        XCTAssertEqual(Difficulty.gapHeight(score: 0, config: c), c.baseGapHeight)
        var prev = Double.infinity
        for s in 0 ... 200 {
            let v = Difficulty.gapHeight(score: s, config: c)
            XCTAssertLessThanOrEqual(v, prev, "gapHeight must be non-increasing")
            XCTAssertGreaterThanOrEqual(v, c.minGapHeight, "gapHeight must never drop below the floor")
            prev = v
        }
        XCTAssertEqual(Difficulty.gapHeight(score: 100_000, config: c), c.minGapHeight)
    }

    /// Extreme score (and Int.max) → finite, clamped, no overflow/trap.
    func testExtremeScoreFiniteClamped() {
        for score in [10000, 1_000_000, Int.max] {
            let ss = Difficulty.scrollSpeed(score: score, config: c)
            let gh = Difficulty.gapHeight(score: score, config: c)
            XCTAssertTrue(ss.isFinite && gh.isFinite, "curves must stay finite at score \(score)")
            XCTAssertEqual(ss, c.maxScrollSpeed, "scrollSpeed clamps at the cap for extreme score")
            XCTAssertEqual(gh, c.minGapHeight, "gapHeight clamps at the floor for extreme score")
        }
    }
}
