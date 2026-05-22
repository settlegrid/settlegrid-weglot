// StateMachineTests.swift — STUB
// PROPERTY: status transitions are correct and reset fully restores. Trap: stepping in .ready/.crashed
// mutating state; reset() that forgets to re-seed rng or clear the accumulator (breaks reproducibility).
import XCTest
@testable import PipeBirdCore

final class StateMachineTests: XCTestCase {

    /// .ready is inert: advancing moves nothing (no bird motion, no spawns, no elapsed).
    func testReadyInert() {
        XCTFail("STUB: from .ready, advance/step; assert state unchanged (Equatable) and no events")
    }

    /// start(): .ready → .playing.
    func testStartTransition() {
        XCTFail("STUB: assert PipeBirdSimulation.start() moves status .ready -> .playing")
    }

    /// .crashed is terminal: advancing leaves bird/pipes/score/elapsed unchanged; only reset() exits.
    func testCrashedTerminal() {
        XCTFail("STUB: from .crashed, advance; assert state unchanged; then reset() returns to .ready")
    }

    /// reset() from any state equals initial(config), rng re-seeded, accumulator cleared (replay reproduces).
    func testResetRestores() {
        XCTFail("STUB: play, reset, assert state == initial(config); replay reproduces the first run")
    }
}
