# IMPLEMENTABILITY AUDIT — SPEC.md
**Scope:** SPEC.md only. **Method:** read every line as an implementer asking "can I build this without guessing?" (distinct from the consistency audit, which checked cross-document agreement). **Outcome:** 1 contract-blocker, 2 major, 5 minor. **All 8 resolved in SPEC.md** (tagged `audit I#` inline). No "must-guess" points remain that would change behavior.

## FINDINGS

| ID | Sev | Where | The gap (what an implementer would have to guess) | Resolution in SPEC |
|---|---|---|---|---|
| **I1** | BLOCKER | §6.6 | `GameEvent` declared `.started` and `.reset`, but **no code path ever emits them** — `start()`/`reset()` return `Void` and `step()` is inert outside `.playing`. They were dead cases; the shell could never react to start/reset, or an implementer might invent an emission path. | **Removed both cases.** Documented that lifecycle transitions are caller-initiated, so the event stream carries only simulation-emergent outcomes (`spawned`/`pipePassed`/`crashed`). |
| **I2** | MAJOR | §6.8 | `step()` takes `rng: inout` but **MUST-scope behavior uses no randomness** (gaps lock to player input). An implementer could either wonder what it's for or *invent* randomness to justify it — silently violating determinism intent. | Documented: `rng` is **reserved and currently unconsumed**; keep it threaded for harness uniformity / future seeded variation; do not invent randomness. |
| **I3** | MAJOR | §6.9 | `start()`/`reset()` semantics from non-`.ready` states, and the restart flow, were unspecified. Does `reset()` auto-play? What does `start()` do from `.crashed`? | Pinned the lifecycle: `reset()` → `.ready` (never auto-plays); `start()` only `.ready→.playing` (else no-op); shell restart = `reset()` then `start()`. |
| **I4** | MINOR | §4.3 | "No core change beyond `Mode`" left it unclear whether `step()` branches on `mode`. | Stated explicitly: the core is **mode-agnostic**; `step()` never reads `mode`; it always scores +1 per cleared pipe. `mode` is a shell-presentation flag. |
| **I5** | MINOR | §6.7 | `initial` described as "centered, empty" — the zero-values (`birdVY`, `elapsed`, `spawnAccumulator`, `score`) were implied, not stated. | Enumerated every field of `initial`. |
| **I6** | MINOR | §7 | First pipe doesn't appear until one `pipeSpacing` of scroll — an implementer might "fix" the empty opening as if it were a bug. | Documented the opening runway as **intentional**, with the optional seed-the-accumulator alternative. |
| **I7** | MINOR | §6.9 | Whether `advance()` gates on status (accumulate/step only while `.playing`?) was unspecified. | Specified: `advance()` always clamps + accumulates + runs `floor(acc/fixedDt)` steps; steps are inert outside `.playing` (safe no-op); accumulator stays bounded. |
| **I8** | MINOR | §6.2 | `nextDouble(in:)` had no derivation, yet `RNGTests` asserts range + reproducibility. | Specified the deterministic mapping (top 53 bits of `next()` → `[0,1)` → scale into range). |

## RIPPLE CHECK (do the fixes break anything already written?)
- **Reference tests:** `DeterminismTests`/`GoldenTraceTests` set `.playing` and call `step` directly, threading `rng` (unused is fine — I2). `CollisionBoundaryTests` references only `.crashed`. None reference `.started`/`.reset`. **No breakage.**
- **`FrameRateIndependenceTests`** uses `start()` from the initial `.ready` state → `.playing` (consistent with I3). **OK.**
- **Stubs/matrix:** `EventTests` covers `spawned`/`pipePassed`/`crashed`/`elapsed` only; `StateMachineTests` covers `start`/`reset`/`crashed`-terminal/`reset`-restores — all consistent with the clarified lifecycle (I3) and explicit `initial` (I5). The traceability matrix needs **no change**. **No breakage.**

## VERIFIED UNAMBIGUOUS (sampled, no finding)
- Collision order + inclusive boundary (§3, §4.2); `step()` 8-step order (§7); scoring boundary `birdX − birdRadius` (§4.3); difficulty formulas (§4.4); spring integration + velocity clamp (§4.1); tuning table single-sourced (§5); `birdTargetY` selection rule (§4.1).

## RESIDUAL (carried, not blocking)
- **F7** (from consistency audit): the weak `testEngineStep_dtScaling_isConsistent` still must be strengthened during Phase A.
- **Empirical-only:** game feel / tuning (§11) is resolvable only on-device in Phase C.
- **Execution-gated:** nothing here has been compiled; spec↔test reconciliation at first compile remains Phase A's first task.

**Verdict:** the launch contract is now clean — every behavioral line is implementable without guessing. Remaining uncertainty is execution-gated (compile, environment, Claude Code schema currency) and is retired by Phase 0 + Gate A, not by further documentation.
