// BirdDynamicsTests.swift — STUB (caught by the traceability matrix; SPEC §8 references it)
// PROPERTY: the bird is an underdamped spring follower — it settles toward its target gap, respects
// the velocity clamp, and OVERSHOOTS at least once (the loseability mechanism). Trap: a critically/
// over-damped controller (no wobble) would make the game un-loseable at steady input.
import XCTest
@testable import PipeBirdCore

final class BirdDynamicsTests: XCTestCase {

    /// Steady aligned target: birdY converges within ε of target within T seconds (overshoot allowed).
    func testSettlesTowardTarget() {
        XCTFail("STUB: with a steady far gap, assert birdY settles within ε of target over ~T seconds")
    }

    /// |birdVY| <= maxBirdSpeed at all times, even with a full-playfield target step.
    func testVelocityClamp() {
        XCTFail("STUB: apply a full-height target step; assert |birdVY| never exceeds maxBirdSpeed")
    }

    /// Underdamped: after a step input, (target - birdY) changes sign at least once (proves overshoot/wobble).
    func testOvershootExists() {
        XCTFail("STUB: assert at least one sign change in (target - birdY) — the wobble must exist")
    }
}
