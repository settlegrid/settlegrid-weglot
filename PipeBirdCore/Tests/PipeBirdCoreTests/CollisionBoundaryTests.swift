// CollisionBoundaryTests.swift
// PipeBirdCoreTests — PRODUCTION TEST (pre-written reference / oracle)
//
// PROPERTY UNDER TEST: PipeBirdEngine.collision(state:config:) is geometrically correct
//   at the boundary — floor, ceiling, pipe body (vertical), AND the pipe CORNER (true
//   circle-vs-rect), under the documented INCLUSIVE rule (contact at distance == radius
//   counts as a crash).
//
// TRAPS THIS PREVENTS:
//   1. Off-by-one / wrong inclusivity at gap edges (we assert exact-contact + just-miss/just-hit).
//   2. A LAZY vertical-only collision (compare birdY±r to gapTop/gapBottom). That impl passes the
//      easy vertical cases but is WRONG near pipe corners. testCorner_* is engineered so a
//      vertical-only impl returns "hit" where true geometry says "miss" (and vice versa). If the
//      production collision passes testCorner_* it is doing the real clamp-based circle-rect test.
//
// CONVENTION (must match SPEC.md): top pipe occupies y in [gapTop, height], bottom pipe y in
//   [0, gapBottom], both across x in [pipe.x, pipe.x + pipeWidth]. Floor at y=0, ceiling at y=height.
//   Collision iff the bird circle (center (birdX, birdY), radius birdRadius) intersects any solid,
//   using distance-to-rect <= radius (inclusive).
//
// AUDITOR ORACLE (hostile-reviewer): confirm the production collision uses a clamp-based nearest-point
//   distance test for pipe rects (not a pure vertical compare), and that floor/ceiling are checked.

import XCTest
@testable import PipeBirdCore

final class CollisionBoundaryTests: XCTestCase {

    private let c = GameConfig.standard

    /// A .playing state with the bird at `birdY` and a single pipe centered on the bird's x.
    /// Pipe straddles the bird (full horizontal overlap) so vertical cases are clean.
    private func straddlingState(birdY: Double,
                                 gapCenterY: Double = 350,
                                 gapHeight: Double = 220) -> GameState {
        var s = GameState.initial(config: c)
        s.status = .playing
        s.birdY = birdY
        s.pipes = [Pipe(id: 0,
                        x: c.birdX - c.pipeWidth / 2,   // straddles bird
                        gapCenterY: gapCenterY,
                        gapHeight: gapHeight,
                        scored: false)]
        return s
    }

    // MARK: floor / ceiling

    func testFloor_contact_isCrash() {
        var s = GameState.initial(config: c)
        s.status = .playing
        s.pipes = []
        s.birdY = c.birdRadius            // birdY - r == 0 (inclusive contact)
        XCTAssertEqual(PipeBirdEngine.collision(state: s, config: c), .floor)
    }

    func testCeiling_contact_isCrash() {
        var s = GameState.initial(config: c)
        s.status = .playing
        s.pipes = []
        s.birdY = c.height - c.birdRadius // birdY + r == height (inclusive contact)
        XCTAssertEqual(PipeBirdEngine.collision(state: s, config: c), .ceiling)
    }

    // MARK: clean pass

    func testCleanPass_centeredInGap_noCrash() {
        let s = straddlingState(birdY: 350, gapCenterY: 350, gapHeight: 220)
        XCTAssertNil(PipeBirdEngine.collision(state: s, config: c))
    }

    // MARK: vertical boundary (gapTop = 350 + 110 = 460)

    func testVertical_exactContact_isInclusiveCrash() {
        // top of circle exactly at gapTop -> inclusive rule => crash
        let s = straddlingState(birdY: 460 - c.birdRadius) // birdY + r == 460 == gapTop
        XCTAssertEqual(PipeBirdEngine.collision(state: s, config: c), .pipeBody)
    }

    func testVertical_justMiss_noCrash() {
        let s = straddlingState(birdY: 460 - c.birdRadius - 0.5) // top of circle = 459.5 < gapTop
        XCTAssertNil(PipeBirdEngine.collision(state: s, config: c))
    }

    func testVertical_justHit_isCrash() {
        let s = straddlingState(birdY: 460 - c.birdRadius + 0.5) // top of circle = 460.5 > gapTop
        XCTAssertEqual(PipeBirdEngine.collision(state: s, config: c), .pipeBody)
    }

    // MARK: CORNER — the discriminating test (defeats vertical-only collision)
    // Pipe placed so the bird overlaps it by only (r-1) horizontally; bird center sits BELOW gapTop
    // (vertically inside the gap). Nearest solid point is the top-pipe's lower-left CORNER (pipe.x, gapTop).
    // True crash depends on distance(center, corner) vs radius — pure vertical compare gets this wrong.

    private func cornerState(distanceToCorner d: Double,
                             gapCenterY: Double = 350,
                             gapHeight: Double = 220) -> GameState {
        let gapTop = gapCenterY + gapHeight / 2
        let dx = c.birdRadius - 1.0                 // 13: horizontal gap from center to pipe's left edge
        let pipeX = c.birdX + dx                    // pipe just to the right of the bird
        // distance^2 = dx^2 + (gapTop - birdY)^2  ->  solve for birdY below gapTop
        let dy = (d * d - dx * dx).squareRoot()
        let birdY = gapTop - dy                     // center vertically inside the gap, near the corner
        var s = GameState.initial(config: c)
        s.status = .playing
        s.birdY = birdY
        s.pipes = [Pipe(id: 0, x: pipeX, gapCenterY: gapCenterY, gapHeight: gapHeight, scored: false)]
        return s
    }

    func testCorner_justMiss_noCrash() {
        // distance to corner = r + 0.5 (> radius) => MISS, even though birdY + r reaches above gapTop.
        let s = cornerState(distanceToCorner: c.birdRadius + 0.5)
        XCTAssertNil(PipeBirdEngine.collision(state: s, config: c),
                     "Vertical-only collision wrongly reports a hit here; correct circle-rect says miss")
    }

    func testCorner_justHit_isCrash() {
        // distance to corner = r - 0.5 (< radius) => HIT on the pipe body.
        let s = cornerState(distanceToCorner: c.birdRadius - 0.5)
        XCTAssertEqual(PipeBirdEngine.collision(state: s, config: c), .pipeBody)
    }

    // MARK: integration — step() wires collision into the state machine

    func testStep_onCollision_setsCrashedAndEmitsOnce_andIsTerminal() {
        var rng = DeterministicRNG(seed: c.seed)
        let crashing = straddlingState(birdY: 470) // center inside top pipe -> crash next step

        let (after, events) = PipeBirdEngine.step(state: crashing, config: c,
                                                  input: Input(targetGapY: 350), rng: &rng)
        XCTAssertEqual(after.status, .crashed)
        XCTAssertEqual(events.filter { if case .crashed = $0 { return true }; return false }.count, 1,
                       "Exactly one .crashed event")

        // Terminal: stepping a crashed state changes nothing and emits nothing.
        let (after2, events2) = PipeBirdEngine.step(state: after, config: c,
                                                    input: Input(targetGapY: 200), rng: &rng)
        XCTAssertEqual(after, after2, "Crashed state is inert to step()")
        XCTAssertTrue(events2.isEmpty, "No events after crash until reset")
    }
}
