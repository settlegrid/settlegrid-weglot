// BirdDynamicsTests.swift (caught by the traceability matrix; SPEC §8 references it)
// PROPERTY: the bird is an underdamped spring follower — it settles toward its target gap, respects the
// velocity clamp, and OVERSHOOTS at least once (the loseability mechanism). Trap: a critically/over-
// damped controller (no wobble) would make the game un-loseable at steady input.
// AUDITOR ORACLE: a far pipe pins the target without colliding; one rng threaded per run; continuous
// settling checked with tolerance, the clamp checked exactly every step.
@testable import PipeBirdCore
import XCTest

final class BirdDynamicsTests: XCTestCase {
    private let c = GameConfig.standard

    /// With a steady reachable target, birdY settles within a small ε of it within a few seconds.
    func testSettlesTowardTarget() {
        var rng = DeterministicRNG(seed: c.seed)
        let target = 500.0
        var state = Fixtures.playing(
            birdY: 200,
            pipes: [Fixtures.pipe(x: c.width * 3, gapCenterY: target, gapHeight: 220)],
            c
        )
        let steps = Int((3.0 / c.fixedDt).rounded())
        for _ in 0 ..< steps {
            (state, _) = PipeBirdEngine.step(
                state: state, config: c, input: Input(targetGapY: target), rng: &rng
            )
        }
        XCTAssertEqual(state.status, .playing, "centered-on-target gap must not crash")
        XCTAssertEqual(
            PipeBirdEngine.birdTargetY(state: state, config: c), target,
            "a pipe centered at the target keeps steering the bird there"
        )
        XCTAssertEqual(state.birdY, target, accuracy: 2.0, "underdamped spring settles near its target")
    }

    /// A full-playfield target step never lets |birdVY| exceed maxBirdSpeed (the clamp holds every step).
    func testVelocityClamp() {
        var rng = DeterministicRNG(seed: c.seed)
        var state = Fixtures.playing(
            birdY: c.birdRadius + 1, // near the floor
            pipes: [Fixtures.pipe(x: c.width * 5, gapCenterY: c.height - 1, gapHeight: 220)],
            c
        )
        let steps = Int((4.0 / c.fixedDt).rounded())
        for _ in 0 ..< steps {
            (state, _) = PipeBirdEngine.step(
                state: state, config: c, input: Input(targetGapY: c.height - 1), rng: &rng
            )
            XCTAssertLessThanOrEqual(abs(state.birdVY), c.maxBirdSpeed, "velocity clamp must hold every step")
            if state.status == .crashed { break } // may fly into the ceiling; clamp must have held until then
        }
    }

    /// Underdamped: (target − birdY) changes sign at least once — the bird overshoots, proving wobble.
    func testOvershootExists() {
        var rng = DeterministicRNG(seed: c.seed)
        let target = 450.0
        var state = Fixtures.playing(
            birdY: 250,
            pipes: [Fixtures.pipe(x: c.width * 4, gapCenterY: target, gapHeight: 220)],
            c
        )
        var prevSign = (target - state.birdY) >= 0
        var sawSignChange = false
        let steps = Int((2.0 / c.fixedDt).rounded())
        for _ in 0 ..< steps {
            (state, _) = PipeBirdEngine.step(
                state: state, config: c, input: Input(targetGapY: target), rng: &rng
            )
            let sign = (target - state.birdY) >= 0
            if sign != prevSign { sawSignChange = true }
            prevSign = sign
            if state.status == .crashed { break }
        }
        XCTAssertTrue(sawSignChange, "underdamped spring must overshoot (sign change in target − birdY)")
    }
}
