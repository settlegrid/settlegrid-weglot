# PIPE BIRD — ONE-SESSION CLAUDE CODE BUILD PLAYBOOK
### A harnessed, audited, context-safe plan to build a shippable iOS game in a single session
*Working title: Pipe Bird (née PIPE DREAMS). Flappy Bird, inverted: the bird is an idiot who trusts you; you control the gap.*

---

## 0. READ THIS FIRST — THE HARSH PREREQUISITE

A native iOS/SpriteKit app **cannot be compiled, run on a simulator, code-signed, or uploaded from a phone.** That requires **macOS + the Xcode toolchain** (`xcodebuild`, the iOS Simulator, `xcrun`, code signing). There is no way around this — it is Apple's constraint, not Claude Code's.

**What "build it via Claude Code on mobile" actually means in practice:**
- Claude Code writes **100% of the Swift** and drives the full build/test loop — *if it runs in a macOS environment with Xcode installed.*
- You can **supervise the session from your phone** (web/app), approving plans and reading audit output, while the agent works against a Mac.
- The **pure logic core** (see §1) is testable with `swift test` on **any** machine with the Swift toolchain (even Linux/CI) — no simulator. This is what lets a phone-supervised session get *real* green test evidence on the part that matters most.

**Harness prerequisite (non-negotiable):** the Claude Code execution environment is **macOS with Xcode + command-line tools**, `swift` on PATH, and ideally `swiftformat`. If that is not available, the session can still produce and *fully test* the logic core, but the simulator-run and ship steps must wait for a Mac. **Do not let the agent claim "it runs" without simulator evidence.** (This is the #1 documented Claude Code failure mode: confident, unverified completion claims.)

---

## 1. THE ARCHITECTURE THAT MAKES THIS ONE-SHOTTABLE

One decision drives everything below:

```
┌──────────────────────────────────────────────┐
│  PipeBirdCore  (Swift Package — LIBRARY)       │
│  • Zero SpriteKit / UIKit / SwiftUI imports    │
│  • Pure value types + one pure step function   │
│  • Deterministic. dt-based. Fully unit-tested. │
│  • Owns: movement, collision, scoring, spawn,  │
│    difficulty curve, state machine, RNG (seeded)│
└──────────────────────────────────────────────┘
                    ▲  (depended on by)
                    │
┌──────────────────────────────────────────────┐
│  PipeBird App  (Xcode — SwiftUI + SpriteKit)   │
│  • SpriteView hosts one SKScene (render only)  │
│  • update(): read input → core.step() → sync   │
│  • Touch → input.targetGapY. NO game logic.    │
│  • NO SKPhysicsBody for gameplay collision.    │
└──────────────────────────────────────────────┘
```

**Why this is the whole game (literally and figuratively):**
- **Testability:** the core compiles and tests headlessly. `swift test` gives a real exit code. Audits become evidence-based, not vibes-based.
- **Determinism:** a pure `step(state, input, dt) -> (state, [Event])` function is reproducible. A test can feed a fixed input sequence + fixed dt and assert exact outcomes. No frame-rate dependence, no physics nondeterminism.
- **Minimal audit surface:** the render shell holds *no* logic to audit. Reviewers focus 90% of attention on one small, pure module.
- **No physics-feel tuning trap:** by banning `SKPhysicsBody` from gameplay (SpriteKit physics is nondeterministic and a tuning black hole), we kill the failure mode that murdered QWOP-style ideas in the original battletest.

**Architecture law (goes in CLAUDE.md, enforced):** *PipeBirdCore imports nothing from Apple UI frameworks. The render shell contains no collision, scoring, or movement math. All randomness is seeded and lives in the core.*

---

## 2. FROZEN SPEC (the source of truth for spec-diff audits)

### 2.1 Core mechanic
- Bird is pinned at `x ≈ 0.30 * width`. The world scrolls left at `scrollSpeed`.
- Pipes spawn at the right edge; each has a **gap** (`gapCenterY`, `gapHeight`).
- The bird is **autonomous and trusting**: its target Y = the gap center you've set for the *next* pipe. It steers toward that target with a capped proportional controller (lag + max speed + max accel). It **cannot teleport** — that lag is the gameplay.
- **Player input:** drag up/down to set `targetGapY` for the upcoming pipe. Once a pipe crosses the bird's x, its gap locks. You are always steering the *next* one.
- **The betrayal:** drag the gap into the floor/ceiling and the trusting bird obediently flies to its death. This is the shareable moment.

### 2.2 Collision & failure
- Crash if the bird's circle intersects a pipe body (outside the gap), the floor, or the ceiling.
- Crash → `.crashed` state → tap to restart (instant).

### 2.3 Scoring & modes
- **Good mode (default):** +1 per pipe safely passed. Score = pipes survived. Track elapsed time too.
- **Evil mode (unlock after first crash, or toggle):** score = fewest gap-moves / shortest time to make the bird crash. Comedic framing ("Betrayals"). Same engine, inverted objective.
- High score persisted locally; Game Center leaderboard (feature-flagged).

### 2.4 Difficulty curve (pure function of score/time)
- `scrollSpeed` rises; `gapHeight` narrows; bird controller gets slightly more sluggish (more "trusting", more lag) at higher scores. All defined as deterministic functions in the core.

### 2.5 Game feel (Should, not Must)
- Bird: googly eyes, "trusting" idle face; brief shocked face on betrayal/crash. Poof particle on crash. Minimal screen shake.
- One-line hint on first run: "Drag to guide the gap. It trusts you."

### 2.6 MoSCoW — what a one-session build must vs may produce
| Priority | Scope |
|---|---|
| **MUST (ship core)** | Logic core + tests green; render shell; Good mode; collision; restart loop; local high score; runs at 60fps in simulator; ad-free; no placeholder crashes |
| **SHOULD** | Game feel (eyes/faces/poof); Evil mode; sound + mute toggle; app icon + launch screen; privacy manifest |
| **COULD** | Game Center leaderboard; StoreKit tip jar; haptics; daily seed |
| **WON'T (this session)** | Multiplayer, ads, accounts, analytics SDKs, backend of any kind |

**Rule:** if context runs low, the agent finishes MUST to a green ship-audit and *stops* — it does not start COULD items half-built.

---

## 3. ORCHESTRATION MODEL

### 3.1 Roles
- **Main agent (Opus):** orchestrator + implementer. Holds the plan, writes code, updates the ledger, invokes subagents at gates. Stays lean by delegating verbose work.
- **Subagents (isolated context, least-privilege tools, loaded from `.claude/agents/`):**
  - `spec-auditor` — *read-only* (Read, Grep, Glob). Diffs implementation against `SPEC.md`; outputs a drift list. Model: Sonnet.
  - `hostile-reviewer` — *read-only* (Read, Grep, Glob). Adversarial bug hunt against a fixed failure-mode checklist. Model: **Opus**. (This is the one that earns its keep.)
  - `test-runner` — Read, **Bash**, Grep. Actually runs `swift test` / `xcodebuild`; pastes fresh exit codes and logs. **Forbidden from claiming pass without fresh evidence.** Model: Sonnet.
  - `ios-researcher` — Read, WebSearch/WebFetch if available (else self-knowledge). Looks up *current* SpriteKit / GameKit / StoreKit / privacy-manifest specifics on demand to avoid stale-API hallucination. Model: Sonnet.

> **Documented gotcha:** the main agent under-delegates by default ("I'll just do it"). The plan therefore **names the subagent explicitly at each gate** ("Invoke `hostile-reviewer` on `PipeBirdCore`…"). Subagents also start with a **clean slate every call** — so every invocation must hand them the file paths and point them at `SPEC.md`; they re-read from disk.

### 3.2 Memory & documentation (survives compaction)
- **`CLAUDE.md`** (project root, < 200 lines): invariants, architecture law, the evidence-before-claims rule, gate protocol. *Advisory but re-injected after `/compact`* — so the rules survive a long session.
- **`SPEC.md`**: the full §2 spec. The frozen source of truth. Spec-auditor diffs against this.
- **`PROGRESS.md`**: the ledger — current phase, gate status, last green test timestamp, open issues. Updated at every gate. Mirrors the in-session TodoWrite task list so state survives context loss.
- Keep `CLAUDE.md` tight (over ~200 lines *reduces* adherence). Big content lives in `SPEC.md`, not `CLAUDE.md`.

### 3.3 Harnessing (hooks = deterministic enforcement)
- **`PostToolUse`** (matcher: Edit/Write on `PipeBirdCore/**/*.swift`) → run `swiftformat` then `swift test` on the package. Fast, headless, immediate feedback. The agent literally cannot drift the core without the tests reacting.
- **`Stop`** (safety net) → block "I'm done" unless `PROGRESS.md` shows the current phase's gate as PASS with a fresh test log. Kills premature completion claims.
- **`SessionStart`** → echo the current phase + open issues from `PROGRESS.md`.
- Pre-approve `swift build/test`, `swiftformat`, `xcodebuild` (named scheme), `git add/commit`, `mkdir` in `settings.json` so the agent doesn't stall on permission prompts mid-flow.
- **Scope discipline:** the per-edit hook runs *only* the fast core tests, never full `xcodebuild` (that runs at gates only) — otherwise every keystroke costs minutes.

### 3.4 Context-risk mitigation for one-shotting (summary)
1. Spec + rules frozen in files that survive compaction (`CLAUDE.md` re-injected; `SPEC.md`/`PROGRESS.md` on disk).
2. Phase gates with a **git commit checkpoint** after each green gate → safe rollback points.
3. Verbose work (audits, big reads, API research) delegated to subagents → main thread stays lean.
4. TodoWrite task list mirrored in `PROGRESS.md`.
5. Plan mode at the start; explicit STOP-and-finish rule if context gets tight (finish MUST, ship-audit, stop).

### 3.5 RECOMMENDATION on your proposed 3-part audit chain
**Adopt it — upgraded.** Your instinct (spec diff → hostile review → test + verify) is correct. My four changes:
1. **Make each part a subagent** (isolated context, least-privilege tools) rather than a main-thread monologue — keeps the orchestrator's context clean and gives the hostile reviewer a genuinely fresh, unbiased read.
2. **Run spec-auditor + hostile-reviewer in parallel** (both read-only, independent), then **test-runner as the hard serial gate** — nothing proceeds until tests are green on fresh evidence.
3. **Embed a light version at every phase boundary**, not only at the end. Bugs caught at Gate A cost minutes; the same bug caught at the final audit costs a context-expensive unwind.
4. **Back it with hooks** so the cheap checks (format, core tests) are enforced continuously and deterministically between the heavier gated reviews.

---

## 4. CONTROL-PLANE FILES (paste-ready)

> **Phase-0 self-calibration caveat:** subagent frontmatter and hook JSON schemas evolve. The kickoff prompt instructs the agent to **verify the current `.claude/agents/` and hooks schema against `code.claude.com/docs` before scaffolding** and adjust the snippets below if they've drifted. Treat these as correct-as-of-authoring templates, not gospel.

### 4.1 `CLAUDE.md` (root)
```markdown
# Pipe Bird — Project Rules (advisory; hooks enforce the hard ones)

## Architecture law (NEVER violate)
- PipeBirdCore imports ZERO Apple UI frameworks (no SpriteKit/UIKit/SwiftUI).
- All movement, collision, scoring, spawning, difficulty, and RNG live in PipeBirdCore.
- The render shell (SpriteKit) contains NO game logic. It reads input, calls core.step(), syncs nodes.
- NO SKPhysicsBody for gameplay. The core owns collision.
- All randomness is seeded (deterministic, reproducible).
- Physics integration is dt-based (frame-rate independent).

## Evidence before claims (NEVER violate)
- Do NOT claim tests pass, build succeeds, or a feature works without FRESH command output in this session.
- "Fresh" = you ran it just now, read the exit code, and it is green. Cached results don't count.

## Gate protocol
- After each phase: run spec-auditor + hostile-reviewer (parallel), then test-runner (hard gate).
- A gate PASSES only when: spec drift = none-or-resolved, hostile findings = resolved-or-accepted-with-reason, tests = green with fresh log.
- On PASS: update PROGRESS.md and git commit a checkpoint.
- If context is tight: finish MUST-scope, run the final ship audit, STOP. Do not half-build COULD items.

## Source of truth
- Spec: SPEC.md. Ledger: PROGRESS.md. Read both at session start and after any /compact.
```

### 4.2 `SPEC.md`
Paste §2 of this playbook verbatim. This is the frozen contract the spec-auditor diffs against.

### 4.3 `PROGRESS.md` (seed)
```markdown
# Pipe Bird — Build Ledger
Current phase: 0 (calibration)
Gate status: A[ ] B[ ] C[ ] D[ ] E[ ] FINAL[ ]
Last green core test: (none yet)
Open issues: (none)
Decisions/accepted-risks log:
```

### 4.4 Subagent — `.claude/agents/hostile-reviewer.md`
```markdown
---
name: hostile-reviewer
description: Adversarial code reviewer. Use at every phase gate and final audit on the named files. Finds bugs; does not fix.
tools: Read, Grep, Glob
model: opus
---
You are a hostile senior reviewer. Assume the code is wrong until proven otherwise.
Review ONLY the files you are given, against this checklist. Output a numbered findings
list (severity: BLOCKER / MAJOR / MINOR), each with file:line and a concrete failure scenario.
Do not fix anything. Do not soften findings.

Checklist:
- Frame-rate dependence: any movement not multiplied by dt? Any per-frame constant that assumes 60fps?
- Determinism: any unseeded randomness? Any reliance on wall-clock or Date()?
- Collision: off-by-one or boundary errors at gap edges, floor, ceiling. Inclusive vs exclusive bounds.
- State machine: unreachable states, missing transitions, double-fire of crash/score events.
- Force-unwraps (!), implicitly unwrapped optionals, array index without bounds check — especially in the per-frame hot path.
- Retain cycles / strong reference loops in the render shell (closures capturing self, SKScene <-> view).
- Architecture-law violations: SpriteKit imports in core; logic in the render shell; SKPhysicsBody used for gameplay.
- Integer/float overflow in the difficulty curve at extreme scores.
- Memory: per-frame allocations, unbounded growth of the pipes array (are off-screen pipes culled?).
- Edge cases: targetGapY clamped to playfield? Pipe spawn while crashed? Restart resets ALL state?
```

### 4.5 Subagent — `.claude/agents/spec-auditor.md`
```markdown
---
name: spec-auditor
description: Diffs implementation against SPEC.md. Use at every phase gate. Reports drift; does not fix.
tools: Read, Grep, Glob
model: sonnet
---
Read SPEC.md, then the named implementation files. Produce two lists:
1) SPEC requirements NOT yet implemented or implemented differently (cite spec section + file:line).
2) Behavior present in code but NOT in spec (scope creep / undocumented decisions).
Be literal. Do not infer intent. Do not fix. Flag every divergence, however small.
```

### 4.6 Subagent — `.claude/agents/test-runner.md`
```markdown
---
name: test-runner
description: Runs the actual build and tests and reports FRESH evidence. The hard gate. Use after spec/hostile review at each phase.
tools: Read, Bash, Grep
model: sonnet
---
Run the commands you are asked to run, in this session, now. Paste the exact command,
the exit code, and the relevant tail of output. NEVER report a status you did not just observe.
If a command fails, stop and report the failure verbatim — do not interpret it as success.
Typical commands: `swift test` (in PipeBirdCore), `xcodebuild -scheme PipeBird -destination 'platform=iOS Simulator,name=iPhone 15' build`.
Output a single verdict line at the end: GATE PASS or GATE FAIL, with the deciding evidence.
```

### 4.7 Subagent — `.claude/agents/ios-researcher.md`
```markdown
---
name: ios-researcher
description: Looks up CURRENT Apple API specifics (SpriteKit, GameKit, StoreKit, privacy manifest, App Store requirements) on demand to prevent stale-API hallucination. Use before writing any Apple-framework integration you are not 100% current on.
tools: Read, WebSearch, WebFetch, Grep
model: sonnet
---
Answer the specific API/integration question with current, citable specifics: required keys,
method signatures, entitlements, Info.plist usage strings, file locations. Prefer developer.apple.com
and code.claude.com. If you cannot verify currency, say so explicitly and flag the assumption.
```

### 4.8 Hooks — `.claude/settings.json` (representative; verify schema in Phase 0)
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command",
            "command": "if echo \"$CLAUDE_TOOL_FILE_PATHS\" | grep -q 'PipeBirdCore/.*\\.swift'; then swiftformat PipeBirdCore >/dev/null 2>&1; (cd PipeBirdCore && swift test 2>&1 | tail -20); fi" }
        ]
      }
    ],
    "Stop": [
      { "hooks": [
        { "type": "command",
          "command": ".claude/hooks/gate-guard.sh" }
      ] }
    ],
    "SessionStart": [
      { "hooks": [
        { "type": "command",
          "command": "echo '--- PROGRESS ---'; sed -n '1,12p' PROGRESS.md" }
      ] }
    ]
  },
  "permissions": {
    "allow": [
      "Bash(swift build:*)", "Bash(swift test:*)", "Bash(swiftformat:*)",
      "Bash(xcodebuild:*)", "Bash(git add:*)", "Bash(git commit:*)", "Bash(mkdir:*)"
    ]
  }
}
```
`.claude/hooks/gate-guard.sh` (idempotent, executable): exits non-zero with a message if `PROGRESS.md` doesn't show the current phase gate as PASS — nudging the agent not to stop mid-phase.

---

## 5. PHASED BUILD PLAN WITH EMBEDDED AUDIT GATES

Every phase ends with the same **gate ritual**: `spec-auditor` ∥ `hostile-reviewer` (parallel) → resolve findings → `test-runner` (hard gate) → update `PROGRESS.md` → `git commit`.

### Phase 0 — Calibrate & scaffold control plane
- Verify current subagent/hook/memory schemas vs `code.claude.com/docs`; adjust §4 files if drifted.
- Create `CLAUDE.md`, `SPEC.md`, `PROGRESS.md`, the four subagents, `settings.json` + `gate-guard.sh`.
- `git init`, initial commit. **Gate 0:** all control-plane files present; hooks load (`InstructionsLoaded`/manual check); subagents listed by `/agents`.

### Phase A — Logic core (the heart) ⟵ *most important phase*
- SwiftPM package `PipeBirdCore` with library + test targets.
- Implement: `GameState`, `PipeState`, `Input`, `Event`; `step(_:input:dt:) -> (GameState,[Event])`; bird controller (capped proportional, dt-based); seeded RNG; pipe spawner with off-screen culling; collision; difficulty curve; `reset()`.
- Write tests alongside: deterministic replay (fixed input+dt → exact state), collision boundaries (just-misses / just-hits at gap edges, floor, ceiling), score increments once per pipe, restart fully resets, difficulty monotonicity, no growth of pipes array over long runs.
- **Gate A:** spec drift none; hostile findings resolved; `swift test` green with fresh log. Commit.

### Phase B — Render shell + wiring
- Xcode app (SwiftUI lifecycle) depending on local `PipeBirdCore`. `SpriteView` hosts `GameScene`.
- `GameScene.update(_:)`: compute dt, build `Input` from touch, call `core.step`, sync `SKNode`s to state, render events (pipe pass, crash). Touch (`touchesMoved`) sets `targetGapY`.
- **Gate B:** `xcodebuild` succeeds; simulator smoke run (bird flies, gaps steer, crash+restart works) — `test-runner` provides launch evidence; spec + hostile review of the shell (esp. retain cycles, no logic leaked into render). Commit.

### Phase C — Game feel (SHOULD)
- Eyes/faces, crash poof, ready/playing/crashed screens, first-run hint, instant restart, optional Evil mode.
- **Gate C:** still 60fps; no new logic in shell; spec + hostile + test green. Commit.

### Phase D — Meta (SHOULD/COULD, feature-flagged so the app runs without them)
- Local high score persistence + mute toggle (SHOULD). Game Center leaderboard + StoreKit tip jar (COULD) behind flags that degrade gracefully if no entitlement/account. Use `ios-researcher` for current GameKit/StoreKit specifics.
- **Gate D:** app builds and runs with flags ON and OFF; spec + hostile + test green. Commit.

### Phase E — Ship-readiness assets
- App icon set, launch screen, `Info.plist` usage strings (only what's used), **PrivacyInfo.xcprivacy** manifest, bundle id, version/build, ad-free confirmed, no placeholder/TODO assets in release.
- **Gate E:** Release-config `xcodebuild` succeeds; assets complete. Commit.

> **Human-in-the-loop (cannot be one-shotted by the agent):** Apple Developer account, provisioning profiles, App Store Connect listing, Game Center leaderboard creation, real device testing, and submission. The plan produces a build that is *ready for* these steps; it does not perform them. Flag them as a post-session checklist.

---

## 6. FINAL END-TO-END SHIP AUDIT (the comprehensive gate)

Run after Gate E. Full-codebase version of the chain, plus a ship checklist. All findings BLOCKER/MAJOR must be resolved (or accepted with written reason in `PROGRESS.md`) before "ship-ready."

**6.1 `spec-auditor` (whole codebase):** every MUST/SHOULD spec item present and matching; no undocumented scope.

**6.2 `hostile-reviewer` (whole codebase, full checklist):** plus a fresh pass for: per-frame allocations / GC pressure, pipes-array unbounded growth, force-unwraps anywhere in the hot path, retain cycles, state desync between core and render, restart leaving stale nodes.

**6.3 `test-runner` (fresh, full):**
- `swift test` on core → green, with a deterministic-replay test included.
- `xcodebuild` Debug **and** Release → succeed.
- Simulator launch + scripted smoke (start → steer → pass pipes → betray → crash → restart) → evidence captured.
- 60fps confirmation (no frame drops in a 60-second run).

**6.4 Ship checklist (binary, no partial credit):**
- [ ] App icon (all required sizes), launch screen present, no default placeholders.
- [ ] `PrivacyInfo.xcprivacy` present and accurate; `Info.plist` has *only* usage strings for things actually used.
- [ ] No analytics/ads/3rd-party SDKs (matches "ad-free" positioning).
- [ ] Game runs end-to-end with Game Center / tip jar flags OFF (degrades gracefully).
- [ ] No `print()` spam / debug overlays in Release; no commented-out dead code in shipped files.
- [ ] Bundle id, version, build number set; deployment target sane (e.g. iOS 17+).
- [ ] Memory stable over a 5-minute run (no monotonic growth).
- [ ] All Phase commits present; `PROGRESS.md` shows every gate PASS.

**6.5 Verdict:** `test-runner` emits a single `SHIP-READY` / `NOT-READY` line with deciding evidence. `NOT-READY` lists the exact blockers. Then the human post-session checklist (signing, App Store Connect, device test, submit) is printed.

---

## 7. MASTER KICKOFF PROMPT (paste into Claude Code to start the session)

```
You are building "Pipe Bird," an iOS game, in one supervised session. Use Opus.

FIRST, run in PLAN MODE and show me the plan before touching anything.

Read this playbook and SPEC.md as your contract. Non-negotiables:
1. Architecture law: PipeBirdCore is a pure Swift package with ZERO Apple-UI imports and
   owns ALL logic (movement, collision, scoring, spawn, difficulty, seeded RNG). The SpriteKit
   shell holds NO logic and uses NO SKPhysicsBody for gameplay. Physics is dt-based.
2. Evidence before claims: never say tests pass / build works / feature works without FRESH
   command output you just ran. Cached results don't count.
3. Work in phases 0→A→B→C→D→E then the FINAL SHIP AUDIT. After every phase run the gate ritual:
   invoke spec-auditor and hostile-reviewer IN PARALLEL on the just-written files, resolve their
   findings, then invoke test-runner as the hard gate. Only on PASS: update PROGRESS.md and
   git commit a checkpoint. Name each subagent explicitly when you invoke it.
4. Maintain PROGRESS.md as the ledger and mirror it with your TodoWrite task list.
5. Use the ios-researcher subagent before writing any Apple-framework integration you are not
   100% current on. Verify subagent/hook schemas against code.claude.com/docs in Phase 0.
6. Scope: finish MUST-scope to a green ship audit first. If context gets tight, finish MUST,
   run the final audit, and STOP — do not half-build COULD items.

Begin with Phase 0. Show me the plan.
```

---

## 8. BATTLETEST OF THIS PLAN (hostile self-audit)

*You asked for the plan to be audited and battletested. Here is the adversarial pass on my own plan, with fixes folded in above. Format: risk → severity → mitigation in plan.*

| # | Risk to the one-shot | Sev | Mitigation (in plan) |
|---|---|:--:|---|
| 1 | iOS can't be compiled/shipped from a phone — silent assumption would sink everything | BLOCKER | §0 states it bluntly; harness = macOS+Xcode; logic core is headlessly testable so phone-supervised work still gets real evidence |
| 2 | Agent claims "tests pass / it runs" without running anything | BLOCKER | Evidence-before-claims in CLAUDE.md; test-runner must paste exit codes; Stop hook blocks premature done |
| 3 | SpriteKit physics nondeterminism → tuning black hole, un-auditable | BLOCKER | Architecture law bans SKPhysicsBody for gameplay; core owns collision; deterministic dt-based step |
| 4 | Frame-rate-dependent movement (works at 60, breaks at 120Hz ProMotion) | MAJOR | dt-based integration mandated + hostile-reviewer checklist item + deterministic replay test |
| 5 | Main agent under-delegates; subagents never fire | MAJOR | Plan names each subagent explicitly at each gate; kickoff prompt mandates parallel invocation |
| 6 | Subagents have no memory / clean slate each call | MAJOR | Every invocation hands them file paths + points at SPEC.md (they re-read from disk) |
| 7 | Context exhaustion mid-build loses the plan/state | MAJOR | CLAUDE.md survives compaction (re-injected); SPEC/PROGRESS on disk; git checkpoints per gate; verbose work delegated |
| 8 | Per-edit hook running full xcodebuild stalls the session | MAJOR | PostToolUse runs ONLY fast headless core tests + format; xcodebuild only at gates |
| 9 | CLAUDE.md bloated → adherence drops | MAJOR | Kept < 200 lines; full spec lives in SPEC.md, not CLAUDE.md |
| 10 | Scope creep eats the session; nothing ships | MAJOR | MoSCoW; MUST-first rule; "if tight, finish MUST + audit + STOP" |
| 11 | Game Center/StoreKit need accounts/entitlements an agent can't provision | MAJOR | Feature-flagged with graceful degradation; flagged as human-in-loop; app runs without them |
| 12 | Stale Apple/Claude-Code API knowledge → hallucinated signatures | MAJOR | Phase-0 schema self-calibration; ios-researcher subagent for any uncertain integration |
| 13 | Read-only auditors can't run tests; or test-runner over-privileged | MINOR | Tools scoped per subagent: auditors read-only, only test-runner gets Bash |
| 14 | Hook JSON / subagent frontmatter schema may have drifted since authoring | MINOR | Templates flagged "verify in Phase 0"; not asserted as final |
| 15 | Pipes array grows unbounded over a long run (slow leak) | MINOR | Off-screen culling in spec; explicit hostile + final-audit memory-stability checks |
| 16 | Restart leaves stale state/nodes → "ghost" bugs | MINOR | `reset()` test (full state reset) + hostile checklist item + final audit |

**Assumptions this plan makes explicit (so they can be checked, not assumed):**
- Execution env is macOS with Xcode + `swift` (and ideally `swiftformat`) on PATH. *If false → core still builds/tests; simulator + ship steps wait for a Mac.*
- Claude Code subagents, `.claude/agents/` frontmatter, `settings.json` hooks, CLAUDE.md memory, and plan mode behave as the current `code.claude.com` docs describe. *Phase 0 re-verifies.*
- The Swift toolchain version supports the package + test layout used. *First `swift build` in Phase A confirms.*

**Verdict on the plan:** the design removes the two failure modes that actually kill one-shot game builds — un-auditable physics and unverifiable completion claims — by making the logic deterministic, headlessly testable, and gated on fresh evidence enforced by hooks. Residual risk concentrates in environment/provisioning (Mac, Apple account) and is correctly pushed out of the agent's scope and into a flagged human checklist. **The plan is sound to execute as written**, with Phase 0 self-calibration as the one cheap insurance step against tooling drift.
```
