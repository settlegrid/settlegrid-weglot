// RobustnessTests.swift
// PROPERTY: long runs stay finite and memory-bounded. Trap: NaN/Inf from a stiff spring at large dt
// (mitigated by fixedDt); pipes array growing without culling (a slow leak). AUDITOR ORACLE: the
// simulation is kept actively integrating for ~10 min by resetting on each crash; one rng per run.
@testable import PipeBirdCore
import XCTest

final class RobustnessTests: XCTestCase {
    private let c = GameConfig.standard

    /// ~10 minutes of active play (resetting on crash) with random valid inputs: all values stay finite.
    func testLongRunFinite() {
        var sim = PipeBirdSimulation(config: c)
        sim.start()
        var inputRNG = DeterministicRNG(seed: 0xFEED_FACE)
        let frames = Int((600.0 / (1.0 / 60.0)).rounded()) // 10 min at 60 fps
        for _ in 0 ..< frames {
            let y = inputRNG.nextDouble(in: 0 ... c.height)
            _ = sim.advance(realDelta: 1.0 / 60.0, input: Input(targetGapY: y))
            XCTAssertTrue(sim.state.birdY.isFinite, "birdY must stay finite")
            XCTAssertTrue(sim.state.birdVY.isFinite, "birdVY must stay finite")
            XCTAssertTrue(sim.state.elapsed.isFinite, "elapsed must stay finite")
            XCTAssertTrue(sim.state.spawnAccumulator.isFinite, "spawnAccumulator must stay finite")
            if sim.state.status == .crashed {
                sim.reset()
                sim.start()
            }
        }
    }

    /// The pipes array never exceeds ceil(width / pipeSpacing) + 2 (culling keeps memory bounded).
    func testPipesArrayBounded() {
        let bound = Int((c.width / c.pipeSpacing).rounded(.up)) + 2
        var sim = PipeBirdSimulation(config: c)
        sim.start()
        var inputRNG = DeterministicRNG(seed: 0x00C0_FFEE)
        for _ in 0 ..< 40000 {
            let y = inputRNG.nextDouble(in: 0 ... c.height)
            _ = sim.advance(realDelta: 1.0 / 60.0, input: Input(targetGapY: y))
            XCTAssertLessThanOrEqual(sim.state.pipes.count, bound, "pipes array must stay bounded")
            if sim.state.status == .crashed {
                sim.reset()
                sim.start()
            }
        }
    }
}
