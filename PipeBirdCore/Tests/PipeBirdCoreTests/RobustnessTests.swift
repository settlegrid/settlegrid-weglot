// RobustnessTests.swift — STUB
// PROPERTY: long runs stay finite and memory-bounded. Trap: NaN/Inf from a stiff spring at large dt
// (mitigated by fixedDt); pipes array growing without culling (a slow leak).
import XCTest
@testable import PipeBirdCore

final class RobustnessTests: XCTestCase {

    /// 10-minute simulated run (fixed dt) with random valid inputs: birdY/birdVY/elapsed stay finite.
    func testLongRunFinite() {
        XCTFail("STUB: simulate ~10 min of steps with random valid targetGapY; assert all values finite")
    }

    /// Over the long run, pipes.count <= ceil(width/pipeSpacing)+2 at all times (culling works).
    func testPipesArrayBounded() {
        XCTFail("STUB: during a long run, assert pipes.count never exceeds ceil(width/pipeSpacing)+2")
    }
}
