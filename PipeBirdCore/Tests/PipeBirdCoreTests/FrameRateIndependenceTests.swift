// FrameRateIndependenceTests.swift
// PipeBirdCoreTests — PRODUCTION TEST (pre-written reference / oracle)
//
// PROPERTY UNDER TEST: the fixed-timestep accumulator makes the simulation independent of how
//   real time is chunked. The same total wall-time and the same (constant) input must yield the
//   same physics whether frames arrive at 60Hz or 120Hz (ProMotion).
//
// WHY NEAR-EXACT, NOT BIT-EXACT: the accumulator does floating-point adds (acc += realDelta).
//   Summing 1/60 vs 1/120 to reach the same total accrues different rounding, so the final
//   *remainder* — and occasionally the count of fixed sub-steps by ±1 at the very end — can differ.
//   Therefore: DISCRETE outcomes (score, pipe count, status) must match EXACTLY, and CONTINUOUS
//   outcomes (birdY) must match within a tight tolerance. That split is the correct contract.
//
// TRAPS THIS PREVENTS:
//   - Accumulator that resets to 0 instead of subtracting fixedDt (loses remainder -> chunking changes
//   physics).
//   - Movement not multiplied by dt (works at one rate, breaks at another).
//   - Using realDelta directly as the integration dt instead of the fixed sub-step.
//
// PREREQUISITE: realDelta per call must be <= config.maxRealDelta (the anti-spiral clamp). We use
//   1/60 and 1/120, both well under it. (A single huge advance is intentionally lossy and is NOT
//   what this property is about.)
//
// AUDITOR ORACLE (hostile-reviewer): confirm advance() clamps realDelta, accumulates, runs
//   floor(acc / fixedDt) steps, and SUBTRACTS fixedDt per step (carrying the remainder).

@testable import PipeBirdCore
import XCTest

final class FrameRateIndependenceTests: XCTestCase {
    private let c = GameConfig.standard

    /// Constant input isolates the accumulator: any divergence is timestep handling, not input timing.
    private func runConstantInput(totalTime: Double, perFrame: Double) -> GameState {
        var sim = PipeBirdSimulation(config: c)
        sim.start()
        let frames = Int((totalTime / perFrame).rounded())
        let steady = Input(targetGapY: 300)
        for _ in 0 ..< frames {
            _ = sim.advance(realDelta: perFrame, input: steady)
        }
        return sim.state
    }

    func testSameWallTime_differentRefreshRates_matchPhysics() {
        let total = 2.0
        let at60 = runConstantInput(totalTime: total, perFrame: 1.0 / 60.0)
        let at120 = runConstantInput(totalTime: total, perFrame: 1.0 / 120.0)

        // Discrete outcomes must be identical.
        XCTAssertEqual(at60.status, at120.status)
        XCTAssertEqual(at60.score, at120.score)
        XCTAssertEqual(at60.pipes.count, at120.pipes.count)

        // Continuous outcome: tight tolerance (accumulator float-rounding only).
        XCTAssertEqual(at60.birdY, at120.birdY, accuracy: 1e-3)
        XCTAssertEqual(at60.birdVY, at120.birdVY, accuracy: 1e-3)
    }

    /// STRENGTHENED (audit F7): replaces the shipped weak smell test with a real two-part check.
    /// (1) Driving the simulation at perFrame == fixedDt must reproduce direct engine stepping EXACTLY,
    ///     including the event stream — the driver's single-fixed-step path IS pure engine stepping.
    /// (2) Integrating the same wall-time at fixedDt vs fixedDt/2 must keep the continuous trajectory
    ///     close: movement is dt-scaled, not per-frame constant (a per-frame-constant bug diverges).
    func testEngineStep_dtScaling_isConsistent() {
        let steady = Input(targetGapY: 450)
        let n = 600

        // (1a) Engine-direct from the canonical initial playing state.
        var rngA = DeterministicRNG(seed: c.seed)
        var direct = GameState.initial(config: c)
        direct.status = .playing
        var directEvents: [GameEvent] = []
        for _ in 0 ..< n {
            let (next, evs) = PipeBirdEngine.step(state: direct, config: c, input: steady, rng: &rngA)
            direct = next
            directEvents.append(contentsOf: evs)
        }

        // (1b) Driver at perFrame == fixedDt must match (1a) bit-for-bit, both state and events.
        var sim = PipeBirdSimulation(config: c)
        sim.start()
        var driverEvents: [GameEvent] = []
        for _ in 0 ..< n {
            driverEvents.append(contentsOf: sim.advance(realDelta: c.fixedDt, input: steady))
        }
        XCTAssertEqual(sim.state, direct, "driver@fixedDt must equal direct engine stepping, exactly")
        XCTAssertEqual(driverEvents, directEvents, "event streams must match exactly")

        /// (2) dt-scaling: integrate 1.0s of spring motion (a far pipe pins the target, no spawn/collision)
        /// at fixedDt vs fixedDt/2. The continuous trajectory must converge to within 1% of the move.
        func birdYAfterOneSecond(dt: Double) -> Double {
            var cc = c
            cc.fixedDt = dt
            var rng = DeterministicRNG(seed: cc.seed)
            var s = Fixtures.playing(
                birdY: 250,
                pipes: [Fixtures.pipe(x: cc.width * 6, gapCenterY: 450, gapHeight: 220)],
                cc
            )
            let steps = Int((1.0 / dt).rounded())
            for _ in 0 ..< steps {
                (s, _) = PipeBirdEngine.step(state: s, config: cc, input: steady, rng: &rng)
            }
            return s.birdY
        }
        let full = birdYAfterOneSecond(dt: c.fixedDt)
        let half = birdYAfterOneSecond(dt: c.fixedDt / 2)
        XCTAssertTrue(full.isFinite && half.isFinite, "no NaN/Inf under repeated stepping")
        XCTAssertEqual(full, half, accuracy: 2.0, "halving dt must change the trajectory only slightly")
    }
}
