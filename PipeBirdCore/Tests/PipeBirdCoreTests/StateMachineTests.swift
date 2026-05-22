// StateMachineTests.swift
// PROPERTY: status transitions are correct and reset fully restores. Trap: stepping in .ready/.crashed
// mutating state; reset() that forgets to re-seed rng or clear the accumulator (breaks reproducibility).
// AUDITOR ORACLE: full GameState compared with ==; one rng threaded per run.
@testable import PipeBirdCore
import XCTest

final class StateMachineTests: XCTestCase {
    private let c = GameConfig.standard

    /// .ready is inert via both the engine and the driver: nothing moves, no events.
    func testReadyInert() {
        var rng = DeterministicRNG(seed: c.seed)
        let ready = GameState.initial(config: c)
        let (after, evs) = PipeBirdEngine.step(
            state: ready, config: c, input: Fixtures.varyingInput(at: 0), rng: &rng
        )
        XCTAssertEqual(after, ready, "engine step on .ready returns it unchanged")
        XCTAssertTrue(evs.isEmpty)

        var sim = PipeBirdSimulation(config: c)
        let s0 = sim.state
        let driverEvents = Fixtures.drive(&sim, frames: 240, input: Fixtures.varyingInput)
        XCTAssertEqual(sim.state, s0, "advancing a .ready simulation moves nothing")
        XCTAssertTrue(driverEvents.isEmpty)
    }

    /// start() moves .ready → .playing and is a no-op when already playing.
    func testStartTransition() {
        var sim = PipeBirdSimulation(config: c)
        XCTAssertEqual(sim.state.status, .ready)
        sim.start()
        XCTAssertEqual(sim.state.status, .playing)
        sim.start()
        XCTAssertEqual(sim.state.status, .playing, "start() is idempotent once playing")
    }

    /// .crashed is terminal: advancing changes nothing; only reset() returns to .ready.
    func testCrashedTerminal() {
        var sim = PipeBirdSimulation(config: c)
        sim.start()
        var crashed = false
        for i in 0 ..< 8000 {
            _ = sim.advance(realDelta: 1.0 / 60.0, input: Fixtures.varyingInput(at: i))
            if sim.state.status == .crashed { crashed = true
                break
            }
        }
        XCTAssertTrue(crashed, "the underdamped bird under varying input must eventually crash")

        let frozen = sim.state
        let evs = Fixtures.drive(&sim, frames: 300, input: Fixtures.varyingInput)
        XCTAssertEqual(sim.state, frozen, "crashed is terminal: advancing changes nothing")
        XCTAssertTrue(evs.isEmpty, "no events after crash")

        sim.reset()
        XCTAssertEqual(sim.state.status, .ready)
        XCTAssertEqual(sim.state, GameState.initial(config: c), "reset() restores the initial state")
    }

    /// reset() restores initial(config), re-seeds the rng, and clears the accumulator → replay reproduces.
    func testResetRestores() {
        var sim = PipeBirdSimulation(config: c)
        func play() -> GameState {
            sim.start()
            for i in 0 ..< 1500 {
                _ = sim.advance(realDelta: 1.0 / 60.0, input: Fixtures.varyingInput(at: i))
            }
            return sim.state
        }
        let first = play()
        sim.reset()
        XCTAssertEqual(sim.state, GameState.initial(config: c), "reset returns to initial")
        let second = play()
        XCTAssertEqual(first, second, "reset re-seeds + clears accumulator so the replay reproduces exactly")
    }
}
