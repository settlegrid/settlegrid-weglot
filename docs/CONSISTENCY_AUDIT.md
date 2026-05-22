# CONSISTENCY AUDIT — PIPE BIRD DOCS (pre-build)
**Scope:** the Build Playbook, the Phase-A spec, the four reference test files, and the reference-test orchestration guide.
**Method:** consolidate all into one `SPEC.md`; reconciliation surfaces drift. All findings below are **resolved in `SPEC.md`** unless marked otherwise.
**Outcome:** 2 internal contradictions, 4 tightenings, 1 weak test (owned), 1 harness-honesty issue. No blocking inconsistencies remain in the spec; two items are flagged as work for the implementing agent.

---

## FINDINGS

| ID | Area | Finding | Severity | Resolution |
|---|---|---|---|---|
| **F1** | Phase-A spec, `Pipe` | `rightEdge` shown as a computed property on `Pipe` (needs `pipeWidth`, which is **not** on `Pipe`) *and* a note recommending edge computation in the engine — a self-contradiction. | MAJOR | `Pipe` is pure data; `rightEdge = pipe.x + config.pipeWidth` computed **only** in `PipeBirdEngine`. No `rightEdge` on `Pipe`. (SPEC §3, §6.5, §6.8) |
| **F2** | Reference tests ↔ API | Tests construct `Pipe(id:x:gapCenterY:gapHeight:scored:)` but the spec gave `Pipe` no public memberwise init. | MINOR (addendum) | Added `public init(...)` to `Pipe`. (SPEC §6.5) |
| **F3** | Phase-A spec, scoring vs targeting | Scoring boundary was `rightEdge < birdX` while the bird-target boundary was `rightEdge > birdX − birdRadius`, leaving an overlap window where a pipe could **both score and crash** the bird in one step. | MINOR | Unified both at `birdX − birdRadius`: a pipe scores only once fully cleared (`rightEdge ≤ birdX − birdRadius`); same threshold partitions "active vs behind." Clean, no overlap. (SPEC §4.3, §7 step 6) |
| **F4** | Phase-A spec, collision | "circle-vs-pipe-rects for the **nearest** overlapping pipe" was ambiguous (which pipe, ties). | MINOR | Defined order: floor → ceiling → **iterate all pipes**, first solid contact wins. At most ~2 pipes are ever near the bird. (SPEC §4.2) |
| **F5** | Phase-A spec, spawn | Spawn used a single `if spawnAccumulator >= pipeSpacing`. Safe at default dt (≤3 u/step vs 240 spacing) but brittle to config changes. | MINOR | `while spawnAccumulator >= pipeSpacing { spawn; spawnAccumulator -= pipeSpacing }`. (SPEC §7 step 4) |
| **F6** | Phase-A spec, `Vec2` | `Vec2` exposed publicly but unused by the engine → would read to the spec-auditor as undocumented/unused surface. | MINOR | Marked **OPTIONAL**: include only if the shell needs it, else omit. (SPEC §6.1) |
| **F7** | `FrameRateIndependenceTests.swift` | `testEngineStep_dtScaling_isConsistent` instantiates a `PipeBirdSimulation` it never uses and falls back to loose invariants — the weakest artifact produced. | WEAK TEST | **Flagged for the agent to strengthen** in Phase A into a real direct-stepping comparison (or replace). Recorded in SPEC §8. *Not yet fixed in code* — deliberate, so the agent owns the corrected version against the live API. |
| **F8** | Harness (`gate-guard.sh` / Stop hook) | The Stop-hook gate reads `PROGRESS.md`, which the **agent itself writes** → the gating is advisory, not the "deterministic" enforcement the playbook implies. | MEDIUM (honesty) | Documented as advisory; **real** enforcement is the PostToolUse hook running actual tests. Recommend strengthening `gate-guard.sh` to also require (a) a git commit within the current phase and (b) a fresh test-output artifact timestamp. *To apply when the control-plane bundle is finalized.* |

---

## VERIFIED CLEAN (cross-checked, no drift)

- **Constants:** every value in the §5 tuning table is consistent across all documents; no contradictory defaults found.
- **Seed:** `0xA5A5_5A5A_C0DE_F00D` is identical in the config default, `DeterminismTests` (`config.seed`), and `GoldenTraceTests` (explicitly pinned). Reproducibility holds across files.
- **Reference-test literals trace to `.standard`:**
  - Collision: `gapTop = 460` = `gapCenterY 350 (= height/2)` + `gapHeight 220/2`; bird radius referenced via `c.birdRadius` (14), not hardcoded. ✔
  - Straddle geometry: pipe `x = birdX − pipeWidth/2 = 90`, `rightEdge = 150`, bird at `120` fully inside with 30u margin > radius 14. ✔
  - Corner geometry: `dx = birdRadius − 1 = 13`, `pipeX = 133`; circle right tip `134 > 133` (1u overlap); center left of pipe and below `gapTop` → nearest point is the corner, so the test genuinely requires the clamp-based distance test. ✔
- **Golden checkpoints:** `totalSteps 6000 / checkpointEvery 500` → 12 checkpoints (steps 0…5500). ✔
- **Timestep usage:** `FrameRateIndependenceTests` uses `1/60` and `1/120`, both well under `maxRealDelta 0.25`. ✔
- **Damping ratio:** `ζ = 6/(2√28) ≈ 0.567` → genuinely underdamped, satisfying the loseability invariant and the overshoot assertion in `BirdDynamicsTests`. ✔
- **Role discipline:** `spec-auditor` and `hostile-reviewer` are read-only and instructed not to fix; only `test-runner` has Bash. No role bleed. ✔

---

## DOCUMENT STATUS AFTER THIS PASS
- **`SPEC.md`** — now the single authoritative source. Diff target for `spec-auditor`.
- **Build Playbook §2** and the **standalone Phase-A spec** — **superseded** by `SPEC.md` for any conflict; keep as narrative/rationale only.
- **Reference-test orchestration guide** — still current; its three "API addenda" are now folded into `SPEC.md` (F1–F3 cover them).

## RESIDUAL ACTIONS (carry into the next build steps)
1. **F7:** strengthen/replace the weak frame-rate test during Phase A against the live API.
2. **F8:** harden `gate-guard.sh` (git-commit recency + test-artifact freshness) when finalizing the control-plane bundle; until then, treat ledger-based gating as advisory and rely on PostToolUse tests for real enforcement.
3. Re-run a quick `spec-auditor` pass against `SPEC.md` at the end of Phase 0 to confirm the scaffolded code's API matches §6 before engine logic is written.
