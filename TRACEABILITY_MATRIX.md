# TRACEABILITY MATRIX — SPEC → TESTS
*Proves every behavioral requirement in SPEC.md maps to a named test. `[ref]` = pre-written reference file; `[stub]` = agent fills the body (currently `XCTFail`). Gate A is not done until every row is green.*

| SPEC ref | Requirement | Test(s) |
|---|---|---|
| §2.6 | Determinism: same inputs → identical state + events | `DeterminismTests.testStepLevel_…` `[ref]`, `…testSimulation_sameAdvanceSchedule…` `[ref]` |
| §2.5 / §6.2 | All randomness via seeded reproducible RNG | `RNGTests.testSameSeedSameSequence` `[stub]`, `…testNextDoubleInRange` `[stub]`, `DeterminismTests.testReset_reseeds…` `[ref]` |
| §2.4 / §4.1 | dt-based, frame-rate independent (60↔120Hz) | `FrameRateIndependenceTests.testSameWallTime_differentRefreshRates…` `[ref]` |
| §4.1 | Bird is underdamped (overshoots) and velocity-clamped | `BirdDynamicsTests.testSettlesTowardTarget / testVelocityClamp / testOvershootExists` `[stub]`, `FrameRateIndependenceTests.testEngineStep_dtScaling…` `[ref, F7: strengthen]` |
| §4.2 / §3 | Collision: floor / ceiling / pipe body, inclusive | `CollisionBoundaryTests.testFloor…`, `…testCeiling…`, `…testVertical_*` `[ref]` |
| §4.2 | Collision: true circle-vs-rect at the **corner** | `CollisionBoundaryTests.testCorner_justMiss/justHit` `[ref]` |
| §7 step 7 | step() wires collision → .crashed once, terminal | `CollisionBoundaryTests.testStep_onCollision_…` `[ref]`, `EventTests.testCrashedFiresOnce` `[stub]` |
| §4.1 / §7 step 4 | Pipes spawn on cadence; gap locks at spawn | `SpawningTests.testSpawnCadenceCount`, `…testRemainderCarry`, `…testGapLockedAtSpawnValue` `[stub]` |
| §4.4 / §7 step 4 | Spawned gapHeight from difficulty curve | `SpawningTests.testGapHeightFromDifficultyAtSpawn` `[stub]` |
| §4.3 / §7 step 6 | Score once per pipe, monotonic, none while crashed | `ScoringTests.testScoreOncePerPipe`, `…testScoreMonotonic`, `…testNoScoreWhileCrashed` `[stub]` |
| §4.4 | Difficulty monotonic, clamped, overflow-safe | `DifficultyTests.testScrollSpeedMonotonicCapped`, `…testGapHeightMonotonicFloored`, `…testExtremeScoreFiniteClamped` `[stub]` |
| §7 step 1 / §4 | Status machine: ready inert, start, crashed terminal, reset restores | `StateMachineTests.testReadyInert`, `…testStartTransition`, `…testCrashedTerminal`, `…testResetRestores` `[stub]` |
| §6.6 / §7 | Events: spawned ids monotonic, pipePassed carries score, elapsed only while playing | `EventTests.testSpawnedOncePerSpawnMonotonicIDs`, `…testPipePassedCarriesScore`, `…testElapsedOnlyWhilePlaying` `[stub]` |
| §2 / §4 | Long-run finiteness + bounded pipes array (no leak) | `RobustnessTests.testLongRunFinite`, `…testPipesArrayBounded` `[stub]` |
| §8 | Frozen golden regression anchor | `GoldenTraceTests.testGoldenTrace` `[ref, record once]` |

**Coverage check:** every MUST behavior in SPEC §4/§6/§7 appears at least once. Gaps to watch while implementing:
- `BirdDynamicsTests` exists as a **stub** (settle-toward-target, velocity clamp, overshoot/wobble) — the agent fills its bodies like the other stubs. Total stub files: **8** (RNG, Spawning, Scoring, Difficulty, StateMachine, Event, Robustness, BirdDynamics).
- F7: the weak `testEngineStep_dtScaling…` must be strengthened or the dt-scaling property re-covered before Gate A.
- Anything the agent adds to the engine that is NOT in this matrix is undocumented scope — the `spec-auditor` should flag it.
