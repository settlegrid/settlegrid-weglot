// ScoringTests.swift — STUB
// PROPERTY: each pipe scores exactly once, when fully cleared (rightEdge <= birdX - birdRadius);
// score is monotonic; no scoring while crashed. Trap: per-frame double counting; scoring a pipe
// the same step the bird crashes (the SPEC unifies the boundary at birdX - birdRadius to prevent this).
import XCTest
@testable import PipeBirdCore

final class ScoringTests: XCTestCase {

    /// One pipe passing the bird increments score by EXACTLY 1, sets scored=true, emits ONE .pipePassed.
    func testScoreOncePerPipe() {
        XCTFail("STUB: drive one pipe past the bird; assert score==1, scored==true, exactly one .pipePassed")
    }

    /// Passing K pipes → score == K; score never decreases.
    func testScoreMonotonic() {
        XCTFail("STUB: pass K aligned pipes; assert score==K and is non-decreasing throughout")
    }

    /// Advancing after .crashed leaves score fixed.
    func testNoScoreWhileCrashed() {
        XCTFail("STUB: from .crashed, advance; assert score unchanged and no .pipePassed emitted")
    }
}
