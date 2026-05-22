// SpawningTests.swift — STUB
// PROPERTY: pipes spawn on a distance cadence, lock the player's targetGapY at spawn, and use the
// difficulty gap height. Trap: resetting the spawn accumulator to 0 (losing remainder) → drift;
// reading targetGapY after spawn (gap should be immutable post-spawn).
import XCTest
@testable import PipeBirdCore

final class SpawningTests: XCTestCase {

    /// After advancing distance D at known speed, pipe count == floor of D/pipeSpacing (account for initial accumulator).
    func testSpawnCadenceCount() {
        XCTFail("STUB: drive a known distance; assert exact spawned-pipe count vs pipeSpacing")
    }

    /// Spawn cadence stays consistent over many spawns (accumulator subtracts pipeSpacing, carries remainder).
    func testRemainderCarry() {
        XCTFail("STUB: over many spawns, assert spacing between spawns is consistent (no drift)")
    }

    /// The spawned pipe's gapCenterY equals clamp(targetGapY at spawn). Changing input later does not move it.
    func testGapLockedAtSpawnValue() {
        XCTFail("STUB: spawn at targetGapY=Y; change input; assert that pipe's gapCenterY is unchanged == clamp(Y)")
    }

    /// The spawned pipe's gapHeight == Difficulty.gapHeight(score, config) at spawn time.
    func testGapHeightFromDifficultyAtSpawn() {
        XCTFail("STUB: assert spawned gapHeight matches Difficulty.gapHeight(currentScore, config)")
    }
}
