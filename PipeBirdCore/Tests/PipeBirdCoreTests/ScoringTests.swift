// ScoringTests.swift
// PROPERTY: each pipe scores exactly once, when fully cleared (rightEdge <= birdX - birdRadius); score
// is monotonic; no scoring while crashed. Trap: per-frame double counting; scoring a pipe the same step
// the bird crashes (the SPEC unifies the boundary at birdX - birdRadius to prevent this).
// AUDITOR ORACLE: one rng threaded per run; hand-built states; .pipePassed payloads run 1,2,3,…
@testable import PipeBirdCore
import XCTest

final class ScoringTests: XCTestCase {
    private let c = GameConfig.standard

    private func pipePassedCount(in events: [GameEvent]) -> Int {
        events.reduce(0) { acc, e in
            if case .pipePassed = e { return acc + 1 }
            return acc
        }
    }

    /// One pipe clearing the bird increments score by exactly 1, sets scored=true, emits one .pipePassed.
    func testScoreOncePerPipe() {
        var rng = DeterministicRNG(seed: c.seed)
        let scoreLine = c.birdX - c.birdRadius
        // Right edge starts just past the score line; gap centered on the bird so passing never crashes.
        let pipeX = scoreLine - c.pipeWidth + 5
        var state = Fixtures.playing(
            birdY: c.height / 2,
            pipes: [Fixtures.pipe(x: pipeX, gapCenterY: c.height / 2, gapHeight: 220)],
            c
        )
        var passes = 0
        for _ in 0 ..< 60 {
            let (next, evs) = PipeBirdEngine.step(
                state: state, config: c, input: Input(targetGapY: c.height / 2), rng: &rng
            )
            state = next
            passes += pipePassedCount(in: evs)
        }
        XCTAssertEqual(state.status, .playing, "centered bird must not crash on a centered gap")
        XCTAssertEqual(passes, 1, "exactly one .pipePassed for one pipe")
        XCTAssertEqual(state.score, 1)
        XCTAssertEqual(state.pipes.first?.scored, true)
    }

    /// Passing many pipes: score is non-decreasing and the payloads run 1,2,3,…; final score == count.
    func testScoreMonotonic() {
        var rng = DeterministicRNG(seed: c.seed)
        var state = Fixtures.playing(birdY: c.height / 2, c)
        var prev = 0
        var expectedNext = 1
        for _ in 0 ..< 3000 {
            let (next, evs) = PipeBirdEngine.step(
                state: state, config: c, input: Input(targetGapY: c.height / 2), rng: &rng
            )
            state = next
            XCTAssertGreaterThanOrEqual(state.score, prev, "score must never decrease")
            prev = state.score
            for e in evs {
                if case let .pipePassed(sc) = e {
                    XCTAssertEqual(sc, expectedNext, "scores must increment by exactly 1 in order")
                    expectedNext += 1
                }
            }
        }
        XCTAssertGreaterThanOrEqual(state.score, 5, "a long centered run accumulates several points")
        XCTAssertEqual(state.score, expectedNext - 1, "final score equals the number of pipes passed")
    }

    /// Advancing a .crashed state leaves the score fixed and emits no .pipePassed.
    func testNoScoreWhileCrashed() {
        var rng = DeterministicRNG(seed: c.seed)
        // An unscored pipe sits right at the score line, but the state is crashed → step must be inert.
        let pipeX = c.birdX - c.birdRadius - c.pipeWidth + 3
        var state = Fixtures.playing(
            birdY: c.height / 2,
            pipes: [Fixtures.pipe(x: pipeX, gapCenterY: c.height / 2, gapHeight: 220)],
            c
        )
        state.status = .crashed
        state.score = 7
        let before = state
        let (after, evs) = PipeBirdEngine.step(
            state: state, config: c, input: Input(targetGapY: c.height / 2), rng: &rng
        )
        XCTAssertEqual(after, before, "crashed state is inert to step()")
        XCTAssertEqual(after.score, 7, "score unchanged while crashed")
        XCTAssertTrue(evs.isEmpty, "no events while crashed")
    }

    /// F3 boundary: a pipe that crashes the bird on its body does NOT also score it. The pipe straddles
    /// the bird with its gap far above (bird in the bottom solid rect), and its right edge is still well
    /// past the score line — so the body crash fires strictly before the pipe could ever clear and score.
    func testCrashingPipeDoesNotScore() {
        var rng = DeterministicRNG(seed: c.seed)
        let pipe = Fixtures.pipe(x: c.birdX - c.pipeWidth / 2, gapCenterY: 600, gapHeight: 120)
        let scoreLine = c.birdX - c.birdRadius
        XCTAssertGreaterThan(pipe.x + c.pipeWidth, scoreLine, "precondition: pipe not yet at the score line")

        let state = Fixtures.playing(birdY: c.height / 2, pipes: [pipe], c)
        let (after, evs) = PipeBirdEngine.step(
            state: state, config: c, input: Input(targetGapY: 600), rng: &rng
        )
        XCTAssertEqual(after.status, .crashed, "bird in the solid region crashes on the pipe body")
        XCTAssertEqual(after.score, 0, "the crashing pipe must not have scored")
        for e in evs {
            if case .pipePassed = e { XCTFail("no .pipePassed for a pipe that crashed the bird") }
        }
        XCTAssertEqual(after.pipes.first(where: { $0.id == pipe.id })?.scored, false)
    }
}
