// EventTests.swift
// PROPERTY: events are emitted correctly and once. Trap: duplicate .crashed; non-monotonic pipe ids;
// elapsed advancing outside .playing. AUDITOR ORACLE: one rng threaded per run; events compared by
// value; crash fires exactly once and silences the stream thereafter.
@testable import PipeBirdCore
import XCTest

final class EventTests: XCTestCase {
    private let c = GameConfig.standard

    /// One .spawned per spawn; ids are contiguous and monotonic via nextPipeID.
    func testSpawnedOncePerSpawnMonotonicIDs() {
        var rng = DeterministicRNG(seed: c.seed)
        var state = Fixtures.playing(birdY: c.height / 2, c)
        var ids: [Int] = []
        for _ in 0 ..< 3000 {
            let (next, evs) = PipeBirdEngine.step(
                state: state, config: c, input: Input(targetGapY: c.height / 2), rng: &rng
            )
            state = next
            for e in evs {
                if case let .spawned(id) = e { ids.append(id) }
            }
        }
        XCTAssertGreaterThanOrEqual(ids.count, 5, "need several spawns")
        for (i, id) in ids.enumerated() {
            XCTAssertEqual(id, i, "pipe ids must be contiguous and monotonic from 0")
        }
        XCTAssertEqual(state.nextPipeID, ids.count, "nextPipeID equals the number of spawns")
    }

    /// Every .pipePassed carries the running score at that moment.
    func testPipePassedCarriesScore() {
        var rng = DeterministicRNG(seed: c.seed)
        var state = Fixtures.playing(birdY: c.height / 2, c)
        var running = 0
        var checked = 0
        for _ in 0 ..< 3000 {
            let (next, evs) = PipeBirdEngine.step(
                state: state, config: c, input: Input(targetGapY: c.height / 2), rng: &rng
            )
            state = next
            for e in evs {
                if case let .pipePassed(sc) = e {
                    running += 1
                    XCTAssertEqual(sc, running, ".pipePassed payload must carry the running score")
                    checked += 1
                }
            }
        }
        XCTAssertGreaterThanOrEqual(checked, 5)
        XCTAssertEqual(state.score, running)
    }

    /// .crashed fires exactly once across a whole run; no events afterward until reset.
    func testCrashedFiresOnce() {
        var sim = PipeBirdSimulation(config: c)
        sim.start()
        var crashedEvents = 0
        var crashed = false
        for i in 0 ..< 8000 {
            let evs = sim.advance(realDelta: 1.0 / 60.0, input: Fixtures.varyingInput(at: i))
            for e in evs {
                if case .crashed = e { crashedEvents += 1 }
            }
            if sim.state.status == .crashed { crashed = true }
        }
        XCTAssertTrue(crashed, "run must reach a crash")
        XCTAssertEqual(crashedEvents, 1, "exactly one .crashed across the whole run")
        let post = Fixtures.drive(&sim, frames: 200, input: Fixtures.varyingInput)
        XCTAssertTrue(post.isEmpty, "no events after a crash until reset")
    }

    /// elapsed accrues only across .playing steps, never in .ready or .crashed.
    func testElapsedOnlyWhilePlaying() {
        var rng = DeterministicRNG(seed: c.seed)

        var ready = GameState.initial(config: c)
        for _ in 0 ..< 10 {
            (ready, _) = PipeBirdEngine.step(
                state: ready, config: c, input: Input(targetGapY: c.height / 2), rng: &rng
            )
        }
        XCTAssertEqual(ready.elapsed, 0, "no elapsed accrues in .ready")

        var playing = Fixtures.playing(birdY: c.height / 2, c)
        let n = 100
        for _ in 0 ..< n {
            (playing, _) = PipeBirdEngine.step(
                state: playing, config: c, input: Input(targetGapY: c.height / 2), rng: &rng
            )
        }
        XCTAssertEqual(
            playing.elapsed,
            Double(n) * c.fixedDt,
            accuracy: 1e-9,
            "elapsed grows by fixedDt/step"
        )

        var crashed = playing
        crashed.status = .crashed
        let before = crashed.elapsed
        for _ in 0 ..< 10 {
            (crashed, _) = PipeBirdEngine.step(
                state: crashed, config: c, input: Input(targetGapY: c.height / 2), rng: &rng
            )
        }
        XCTAssertEqual(crashed.elapsed, before, "no elapsed accrues in .crashed")
    }
}
