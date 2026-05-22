// GoldenTraceTests.swift
// PipeBirdCoreTests — PRODUCTION TEST + HARNESS (pre-written reference / oracle)
//
// WHAT THIS IS: a frozen "golden trace." A canonical scenario (pinned seed + fixed input schedule)
//   is run, and the engine state is captured at fixed checkpoints. Those captured values are
//   committed as `goldenCheckpoints`. From then on, this test fails if ANY future change alters the
//   simulation — even a change that keeps the suite green for the wrong reason.
//
// WHY IT BEATS run-twice-and-compare: determinism tests catch NON-determinism. They do NOT catch a
//   model that is wrong but consistently wrong (a flipped sign, a swapped gap edge). The golden trace
//   pins the ACTUAL trajectory, so a wrong-but-consistent model is caught the moment behavior shifts
//   from the recorded reference. It is the regression anchor for the whole physics core.
//
// COMPARISON CONTRACT (robust across macOS and Linux CI):
//   - DISCRETE fields (status, score, pipeCount, nextPipeID) compared EXACTLY.
//   - CONTINUOUS fields (birdY, birdVY) compared within tolerance (cross-platform last-ULP drift).
//   A real behavior change moves continuous values far more than the tolerance; ULP noise does not.
//
// HOW TO RECORD (one time, by the implementing agent, AFTER the engine is green on its own tests):
//   1. Set `recordMode = true`.
//   2. Run `swift test --filter GoldenTraceTests`. The test prints a ready-to-paste Swift array and
//      FAILS on purpose (so record mode can never be left on by accident).
//   3. Paste the printed array into `goldenCheckpoints`, set `recordMode = false`, commit.
//   The fixture is now frozen. Do not edit it again unless a tuning change is intended and reviewed.
//
// AUDITOR ORACLE: the FINAL ship audit must include this test passing with recordMode == false.
//   If goldenCheckpoints is still the placeholder, the gate is NOT met.

import XCTest
@testable import PipeBirdCore

final class GoldenTraceTests: XCTestCase {

    // Flip to true ONLY to (re)record. Must be false in committed code.
    private static let recordMode = false

    // Continuous-field tolerance: generous enough for cross-platform ULP drift, far tighter than any
    // real behavior change.
    private static let tol = 1e-4

    // Canonical config: standard, but seed pinned here so the fixture is self-describing.
    private var config: GameConfig {
        var c = GameConfig.standard
        c.seed = 0xA5A5_5A5A_C0DE_F00D
        return c
    }

    // Deterministic, trig-free input schedule (kept stable forever; changing it invalidates the fixture).
    private func input(at step: Int) -> Input {
        let ys: [Double] = [350, 250, 480, 180, 520, 300, 420, 360]
        return Input(targetGapY: ys[step % ys.count])
    }

    private let totalSteps = 6_000
    private let checkpointEvery = 500   // -> 12 checkpoints

    struct Checkpoint: Equatable {
        let step: Int
        let status: String   // discrete (stringified for stable literals)
        let score: Int       // discrete
        let pipeCount: Int   // discrete
        let nextPipeID: Int  // discrete
        let birdY: Double    // continuous
        let birdVY: Double   // continuous
    }

    private func capture() -> [Checkpoint] {
        var state = GameState.initial(config: config)
        state.status = .playing
        var rng = DeterministicRNG(seed: config.seed)
        var out: [Checkpoint] = []
        for i in 0..<totalSteps {
            if i % checkpointEvery == 0 {
                out.append(Checkpoint(step: i,
                                      status: "\(state.status)",
                                      score: state.score,
                                      pipeCount: state.pipes.count,
                                      nextPipeID: state.nextPipeID,
                                      birdY: state.birdY,
                                      birdVY: state.birdVY))
            }
            (state, _) = PipeBirdEngine.step(state: state, config: config,
                                             input: input(at: i), rng: &rng)
        }
        return out
    }

    func testGoldenTrace() {
        let actual = capture()

        if Self.recordMode {
            // Emit a paste-ready fixture, then fail so record mode is never silently shipped.
            var lines = ["    private let goldenCheckpoints: [Checkpoint] = ["]
            for cp in actual {
                lines.append("        Checkpoint(step: \(cp.step), status: \"\(cp.status)\", "
                    + "score: \(cp.score), pipeCount: \(cp.pipeCount), nextPipeID: \(cp.nextPipeID), "
                    + "birdY: \(cp.birdY), birdVY: \(cp.birdVY)),")
            }
            lines.append("    ]")
            print("\n=== GOLDEN TRACE (paste into goldenCheckpoints, set recordMode=false) ===")
            print(lines.joined(separator: "\n"))
            print("=== END GOLDEN TRACE ===\n")
            XCTFail("recordMode is ON. Paste the printed fixture, set recordMode=false, and commit.")
            return
        }

        XCTAssertFalse(goldenCheckpoints.isEmpty,
                       "goldenCheckpoints is empty — record the trace before the final ship audit.")
        XCTAssertEqual(actual.count, goldenCheckpoints.count, "checkpoint count drifted")

        for (a, g) in zip(actual, goldenCheckpoints) {
            XCTAssertEqual(a.step,       g.step)
            XCTAssertEqual(a.status,     g.status,     "status drift at step \(g.step)")
            XCTAssertEqual(a.score,      g.score,      "score drift at step \(g.step)")
            XCTAssertEqual(a.pipeCount,  g.pipeCount,  "pipeCount drift at step \(g.step)")
            XCTAssertEqual(a.nextPipeID, g.nextPipeID, "nextPipeID drift at step \(g.step)")
            XCTAssertEqual(a.birdY,  g.birdY,  accuracy: Self.tol, "birdY drift at step \(g.step)")
            XCTAssertEqual(a.birdVY, g.birdVY, accuracy: Self.tol, "birdVY drift at step \(g.step)")
        }
    }

    // PLACEHOLDER — replace with recorded values (see "HOW TO RECORD" above). Empty fails the test
    // by design until frozen, so the ship audit cannot pass on an unrecorded fixture.
    private let goldenCheckpoints: [Checkpoint] = []
}
