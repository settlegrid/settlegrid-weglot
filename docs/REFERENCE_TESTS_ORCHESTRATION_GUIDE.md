# REFERENCE TESTS — ORCHESTRATION GUIDE
### How the Claude Code main agent and its subagents use these four files
*Companion to the Build Playbook and the PipeBirdCore Phase A Spec.*

---

## What these files are

Four **production-ready, drop-in** test files for `Tests/PipeBirdCoreTests/`:

1. `DeterminismTests.swift` — bit-reproducibility (exact `Equatable` equality on state + events).
2. `CollisionBoundaryTests.swift` — floor/ceiling/body/**corner** boundaries under the inclusive rule.
3. `FrameRateIndependenceTests.swift` — the fixed-timestep accumulator (discrete-exact, continuous-tolerant).
4. `GoldenTraceTests.swift` — a record-then-freeze regression anchor that catches *wrong-but-consistent* models.

They are pre-written **because they are the highest-risk tests to get subtly wrong** — the kind that go green over a real bug. Every other test in the Phase A list (Spawning, Scoring, Difficulty, StateMachine, Event, Robustness, RNG) is written by the implementing agent **in the same style and to the same bar.**

---

## How each role uses them

**Main implementing agent (Phase A):**
- Drop these four files in *first*, before writing the engine. They won't compile yet — that's fine; they define the target API surface.
- Implement `PipeBirdCore` until these compile and pass. They are your spec made executable.
- Write the remaining test files mirroring these patterns (header stating property + trap + auditor-oracle note; discrete-exact vs continuous-tolerant discipline; one rng threaded per run; states hand-built for unit isolation).
- Do **not** weaken any assertion to make it pass. If a reference test fails, the engine is wrong, not the test.

**`spec-auditor`:** verify the engine's public API exactly matches what these tests call (names, signatures, the documented `step` order). Any divergence is drift.

**`hostile-reviewer`:** use these as the **bar** for the agent-written tests. Concretely, reject the agent's tests if:
- a "reproducibility" test uses tolerance instead of `==`, or omits the event-list comparison, or news up a fresh rng per step;
- a collision test has no **corner** case (vertical-only collision must be impossible to pass);
- a frame-rate test asserts bit-exact continuous values (wrong — must be discrete-exact + continuous-tolerant);
- the golden fixture is still empty at the final audit.

**`test-runner`:** these run headlessly via `swift test` — no simulator. Paste fresh exit codes. The **final ship audit requires `GoldenTraceTests` passing with `recordMode == false`** and a non-empty fixture.

---

## The one manual step (call it out in PROGRESS.md)

`GoldenTraceTests` ships with an **empty fixture and fails by design.** Exactly once, after the engine is green on all *other* tests:
1. set `recordMode = true` → `swift test --filter GoldenTraceTests` → it prints a paste-ready array and fails on purpose;
2. paste the array into `goldenCheckpoints`, set `recordMode = false`, commit.

After that it is frozen. Re-record **only** on an intended, reviewed tuning change. Log any re-record in `PROGRESS.md`'s decisions list.

---

## API addenda these tests reveal (fold into the Phase A spec before implementing)

The reference tests construct states directly, which surfaces three small public-API requirements:

1. **`Pipe` needs a public memberwise init:** `public init(id: Int, x: Double, gapCenterY: Double, gapHeight: Double, scored: Bool)`.
2. **`GameState` fields must be publicly settable** (already `public var` in the spec — confirm: `status`, `birdY`, `birdVY`, `pipes` are assignable from the test target).
3. **`step()` must be inert outside `.playing`** (the terminal-crash test relies on stepping a `.crashed` state returning it unchanged with no events). This matches `step` order item #1 in the spec — keep it.

These are additive clarifications, not changes. The spec-auditor should treat them as part of the contract.

---

## Why this was the right thing to pre-write (the principle, for future phases)

Pre-write effort goes where failure is **silent and expensive**, not loud and cheap. The render shell (Phase B) fails loudly on a simulator and self-corrects; pre-writing it early would only bloat context. The physics core fails *silently* — a green suite over a real bug — so the highest-leverage artifacts are **concrete oracles** that turn the auditor subagents from prose-reviewers into reference-checkers. Clean-slate subagents are far more reliable checking against a known-correct anchor than reasoning from description. Apply the same rule when deciding what to pre-write for later phases: anchor the silent risks, let the loud ones surface themselves.
