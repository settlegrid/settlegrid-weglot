// SpawningTests.swift
// PROPERTY: pipes spawn on a distance cadence, lock the player's targetGapY at spawn, and use the
// difficulty gap height. Trap: resetting the spawn accumulator to 0 (losing remainder) → drift;
// reading targetGapY after spawn (the gap must be immutable post-spawn).
// AUDITOR ORACLE: one rng threaded per run; hand-built playing states; cadence checked in DISTANCE
// (not step count) so it survives the score-dependent scroll speed.
@testable import PipeBirdCore
import XCTest

final class SpawningTests: XCTestCase {
    private let c = GameConfig.standard

    private func spawnCount(in events: [GameEvent]) -> Int {
        events.reduce(0) { acc, e in
            if case .spawned = e { return acc + 1 }
            return acc
        }
    }

    /// Over a score-0 window, spawned count == floor(scrolled distance / pipeSpacing).
    func testSpawnCadenceCount() {
        var rng = DeterministicRNG(seed: c.seed)
        var state = Fixtures.playing(birdY: c.height / 2, c) // centered bird in a centered gap survives
        let steps = 450
        var spawns = 0
        for _ in 0 ..< steps {
            let (next, evs) = PipeBirdEngine.step(
                state: state, config: c, input: Input(targetGapY: c.height / 2), rng: &rng
            )
            state = next
            spawns += spawnCount(in: evs)
            XCTAssertEqual(state.status, .playing, "centered bird must not crash")
        }
        // Score stayed 0 in this window, so scroll speed is constant: distance = base * dt * steps.
        XCTAssertEqual(state.score, 0, "guard: scroll speed constant only while score == 0")
        let distance = Double(steps) * Difficulty.scrollSpeed(score: 0, config: c) * c.fixedDt
        let expected = Int((distance / c.pipeSpacing).rounded(.down))
        XCTAssertEqual(spawns, expected, "spawned count must equal floor(distance / pipeSpacing)")
        XCTAssertEqual(state.nextPipeID, expected, "nextPipeID advances once per spawn")
    }

    /// Across many spawns, each spawn fires within one step of its ideal cadence point — no drift
    /// (the accumulator subtracts pipeSpacing and carries the remainder; it does NOT reset to 0).
    func testRemainderCarry() {
        var rng = DeterministicRNG(seed: c.seed)
        var state = Fixtures.playing(birdY: c.height / 2, c)
        var cumulativeDistance = 0.0
        var spawnDistances: [Double] = []
        for _ in 0 ..< 3000 {
            let speed = Difficulty.scrollSpeed(score: state.score, config: c) // pre-step score, as in step()
            let (next, evs) = PipeBirdEngine.step(
                state: state, config: c, input: Input(targetGapY: c.height / 2), rng: &rng
            )
            cumulativeDistance += speed * c.fixedDt
            for _ in 0 ..< spawnCount(in: evs) {
                spawnDistances.append(cumulativeDistance)
            }
            state = next
        }
        XCTAssertGreaterThanOrEqual(spawnDistances.count, 5, "need several spawns to detect drift")
        let maxStep = c.maxScrollSpeed * c.fixedDt
        for (i, d) in spawnDistances.enumerated() {
            let ideal = Double(i + 1) * c.pipeSpacing
            XCTAssertGreaterThanOrEqual(d, ideal - 1e-9, "spawn cannot fire before the threshold")
            XCTAssertLessThan(d - ideal, maxStep + 1e-9, "spawn \(i + 1) drifted past one step from cadence")
        }
    }

    /// The spawned pipe locks gapCenterY = clamp(targetGapY) and never moves when input changes later.
    func testGapLockedAtSpawnValue() {
        var rng = DeterministicRNG(seed: c.seed)
        var state = Fixtures.playing(birdY: c.height / 2, c)
        let lockY = 500.0
        var lockedID: Int?
        var i = 0
        while lockedID == nil, i < 2000 {
            let (next, evs) = PipeBirdEngine.step(
                state: state, config: c, input: Input(targetGapY: lockY), rng: &rng
            )
            state = next
            i += 1
            for e in evs {
                if case let .spawned(id) = e { lockedID = id }
            }
        }
        guard let id = lockedID, let pipe = state.pipes.first(where: { $0.id == id }) else {
            return XCTFail("expected at least one spawn within the window")
        }
        let expected = min(max(lockY, pipe.gapHeight / 2), c.height - pipe.gapHeight / 2)
        XCTAssertEqual(pipe.gapCenterY, expected, "gapCenterY locks to clamp(targetGapY) at spawn")

        // Drastically change input; the already-spawned pipe must keep its locked center.
        for _ in 0 ..< 300 {
            let (next, _) = PipeBirdEngine.step(
                state: state, config: c, input: Input(targetGapY: 100), rng: &rng
            )
            state = next
            if let p = state.pipes.first(where: { $0.id == id }) {
                XCTAssertEqual(p.gapCenterY, expected, "locked gap center must be immutable post-spawn")
            }
        }
    }

    /// Each spawned pipe's gapHeight equals Difficulty.gapHeight(currentScore) at the spawn step.
    func testGapHeightFromDifficultyAtSpawn() {
        var rng = DeterministicRNG(seed: c.seed)
        var state = Fixtures.playing(birdY: c.height / 2, c)
        var checked = 0
        for _ in 0 ..< 3000 {
            let expectedGH = Difficulty.gapHeight(score: state.score, config: c)
            let (next, evs) = PipeBirdEngine.step(
                state: state, config: c, input: Input(targetGapY: c.height / 2), rng: &rng
            )
            state = next
            for e in evs {
                if case let .spawned(id) = e, let p = state.pipes.first(where: { $0.id == id }) {
                    XCTAssertEqual(
                        p.gapHeight,
                        expectedGH,
                        "spawned gapHeight must match the difficulty curve"
                    )
                    checked += 1
                }
            }
        }
        XCTAssertGreaterThanOrEqual(checked, 3, "should observe spawns across varying scores")
    }
}
