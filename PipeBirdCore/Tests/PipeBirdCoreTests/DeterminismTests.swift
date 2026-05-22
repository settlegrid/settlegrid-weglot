// DeterminismTests.swift
// PipeBirdCoreTests — PRODUCTION TEST (pre-written reference / oracle)
//
// PROPERTY UNDER TEST: the engine is bit-reproducible. Same (config, seed, input
//   sequence, fixed dt) -> identical GameState AND identical event lists.
//
// TRAP THIS PREVENTS: a "determinism" test that only checks one field (e.g. birdY)
//   or that compares with a loose tolerance. On the SAME machine/toolchain, identical
//   IEEE-754 op sequences are bit-identical, so the correct assertion here is EXACT
//   equality via Equatable — including the event list. A tolerant compare here would
//   silently pass a model that is non-deterministic in pipes/score/events.
//
// AUDITOR ORACLE (hostile-reviewer): any other "reproducibility" test in the suite must
//   (a) compare full GameState with ==, (b) compare event lists with ==, (c) thread ONE
//   rng instance across a run (never a fresh rng per step). Hold the agent's tests to this.

import XCTest
@testable import PipeBirdCore

final class DeterminismTests: XCTestCase {

    private let config = GameConfig.standard

    /// Deterministic, trig-free input schedule that exercises spawns at varied gaps.
    private func input(at step: Int) -> Input {
        let ys: [Double] = [350, 200, 500, 150, 550, 300, 450]
        return Input(targetGapY: ys[step % ys.count])
    }

    // MARK: step-level determinism (the strongest claim: exact equality)

    func testStepLevel_sameInputs_produceBitIdenticalStatesAndEvents() {
        let steps = 4_000   // long enough to spawn, score, and likely crash+stay crashed

        func run() -> (GameState, [GameEvent]) {
            var state = GameState.initial(config: config)
            state.status = .playing
            var rng = DeterministicRNG(seed: config.seed)   // ONE rng threaded through the run
            var events: [GameEvent] = []
            for i in 0..<steps {
                let (next, evs) = PipeBirdEngine.step(state: state,
                                                      config: config,
                                                      input: input(at: i),
                                                      rng: &rng)
                state = next
                events.append(contentsOf: evs)
            }
            return (state, events)
        }

        let (stateA, eventsA) = run()
        let (stateB, eventsB) = run()

        XCTAssertEqual(stateA, stateB, "GameState must be bit-identical across identical runs")
        XCTAssertEqual(eventsA, eventsB, "Event stream must be identical across identical runs")
    }

    // MARK: driver-level determinism (covers accumulator + rng wiring in PipeBirdSimulation)

    func testSimulation_sameAdvanceSchedule_producesIdenticalState() {
        func run() -> GameState {
            var sim = PipeBirdSimulation(config: config)
            sim.start()
            for i in 0..<2_000 {
                _ = sim.advance(realDelta: 1.0 / 60.0, input: input(at: i))
            }
            return sim.state
        }
        XCTAssertEqual(run(), run(), "Two simulations on the same schedule must end identical")
    }

    // MARK: reset reproducibility (rng must re-seed; second run reproduces the first)

    func testReset_reseeds_andReproducesRun() {
        var sim = PipeBirdSimulation(config: config)

        func playOnce() -> GameState {
            sim.start()
            for i in 0..<1_500 {
                _ = sim.advance(realDelta: 1.0 / 60.0, input: input(at: i))
            }
            return sim.state
        }

        let first = playOnce()
        sim.reset()                 // must restore initial state, clear accumulator, re-seed rng
        let second = playOnce()

        XCTAssertEqual(first, second, "reset() must fully restore state so a replay reproduces exactly")
    }
}
