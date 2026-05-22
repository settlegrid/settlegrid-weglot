// EventTests.swift — STUB
// PROPERTY: events are emitted correctly and once. Trap: duplicate .crashed; non-monotonic pipe ids;
// elapsed advancing outside .playing.
import XCTest
@testable import PipeBirdCore

final class EventTests: XCTestCase {

    /// .spawned(pipeID:) fires once per spawn; ids are monotonic via nextPipeID.
    func testSpawnedOncePerSpawnMonotonicIDs() {
        XCTFail("STUB: assert one .spawned per spawn and strictly increasing pipeIDs")
    }

    /// .pipePassed carries the running score.
    func testPipePassedCarriesScore() {
        XCTFail("STUB: assert each .pipePassed payload equals the score at that moment")
    }

    /// .crashed(reason) fires EXACTLY once; no events after it until reset.
    func testCrashedFiresOnce() {
        XCTFail("STUB: drive to a crash; assert exactly one .crashed and zero events on subsequent steps")
    }

    /// elapsed accumulates only across .playing steps.
    func testElapsedOnlyWhilePlaying() {
        XCTFail("STUB: assert elapsed increases only while .playing, not in .ready/.crashed")
    }
}
