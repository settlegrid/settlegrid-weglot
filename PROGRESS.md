# Pipe Bird — Build Ledger

Current phase: B
<!-- gate-guard.sh reads the "Current phase:" line above. Use 0 for setup, then A/B/C/D/E/FINAL. -->
<!-- Phase A is COMPLETE and green on Linux. Phases B–E + FINAL require macOS + Xcode and are
     deferred to a Mac (SwiftUI/SpriteKit/SpriteView/GameKit/StoreKit, xcodebuild, simulator, fps). -->

## Gate status
- [x] Gate 0 — control plane scaffolded, hooks load, subagents listed
- [x] Gate A — logic core green (incl. frozen GoldenTrace)
- [ ] Gate B — render shell builds + simulator smoke   (DEFERRED: macOS + Xcode)
- [ ] Gate C — game feel, still 60fps                  (DEFERRED: macOS + Xcode)
- [ ] Gate D — meta (flags ON and OFF both run)        (DEFERRED: macOS + Xcode)
- [ ] Gate E — ship assets, Release build              (DEFERRED: macOS + Xcode)
- [ ] FINAL — end-to-end ship audit → SHIP-READY        (DEFERRED: macOS + Xcode)

## Last green
- Core test: 2026-05-22 — `make gate` PASS on Swift 6.3.2 / Linux x86_64. `swift test` = 41 tests,
  0 failures (4 reference + 8 agent-written stub files filled + strengthened F7 + frozen GoldenTrace).
  format-check clean (0/21), `swift build` clean (0 warnings). GoldenTrace frozen (12 checkpoints).
- App build: (none yet — Phase B, requires macOS + Xcode)

## Open issues
- (none blocking) Phases B–E and FINAL build/verification are deferred to macOS + Xcode; the Phase-A
  core compiles and is green headlessly via `swift test` (no Apple frameworks, no Foundation).

## Decisions / accepted-risks log
- Carried from CONSISTENCY_AUDIT.md:
  - **F7** — `FrameRateIndependenceTests.testEngineStep_dtScaling_isConsistent` shipped intentionally
    weak; **DONE** — strengthened during Phase A into a real two-part check: (1) driver@fixedDt ==
    direct engine stepping, exact state + event-list equality; (2) a true dt-halving convergence check.
  - **F8** — Stop-hook (`gate-guard.sh`) is advisory and never blocks. Real enforcement is `make gate`.

- Phase 0 (control-plane calibration):
  - Verified hook/subagent schemas against code.claude.com/docs: event names (`PostToolUse`/`Stop`/
    `SessionStart`), the `matcher` key, the stdin `tool_input.file_path` shape, and subagent
    frontmatter (`name`/`description`/`tools`/`model`) all current — no drift. Hooks `chmod +x`'d.
  - `jq` present; `swiftformat` built from source (0.61.1) and installed (the env Setup script provides
    Swift 6.3.2; swiftformat is not part of the toolchain).
  - Harness note: in Claude Code on the web the package's custom subagents do not auto-register as
    selectable types, so the gate ritual (spec-auditor ∥ hostile-reviewer) was run via general-purpose
    agents seeded with the exact `.claude/agents/*.md` prompts; `make gate` was run directly. The
    `.claude/` files remain correct for normal (desktop/CLI) sessions.

- Phase A (engine):
  - **Repo strategy** — this branch (`claude/pipebird-game-build-MC12Y`) was rebuilt as a clean ORPHAN
    holding only the PipeBird package; the SettleGrid template remains on `origin/main` (untouched).
    The uploaded `origin/Pipebird-import` zip branch was left intact as a backup (not deleted).
  - **Makefile pipefail** — default `/bin/sh` lacks pipefail, so `swift test | tee` masked failing
    tests behind tee's exit 0, defeating the documented "non-zero exit = gate fail." Added
    `SHELL := /bin/bash` + `.SHELLFLAGS := -o pipefail -c` so the gate truly fails on build/test failure.
  - **Linux Foundation `Pipe` clash** — on Linux `import XCTest` re-exports Foundation (which has its
    own `Pipe`), making the tests' unqualified `Pipe` ambiguous with `PipeBirdCore.Pipe` (SPEC §6.5).
    Resolved additively with a module-level `typealias Pipe = PipeBirdCore.Pipe` in a new test file
    (`LinuxFoundationShim.swift`) — no provided test file changed, no test semantics altered.
  - **swiftformat `unusedArguments`** — the formatter renamed the intentionally-unconsumed `rng`
    parameter (SPEC §6.8 audit I2) to `_`. Restored the name with a localized
    `// swiftformat:disable unusedArguments` directive in PipeBirdEngine.swift.
  - **GoldenTrace record** — recorded once on Swift 6.3.2 / Linux x86_64 (seed 0xA5A5_5A5A_C0DE_F00D,
    12 checkpoints, the canonical input schedule). Fixture wrapped in `swiftformat:disable wrap
    wrapArguments` so the long data lines stay one-per-Checkpoint (the gate greps `Checkpoint(step:`).
    Re-record only on an intended, reviewed tuning change.

- Gate-A review findings (hostile-reviewer: BLOCKER 0 / MAJOR 0 / MINOR 3; spec-auditor: DRIFT none):
  - **MINOR-1 (accepted, SPEC question)** — F3's "a pipe cannot both score and crash in the same step"
    holds in practice but not at the float-exact boundary (`rightEdge == birdX − birdRadius` with the
    bird exactly on a solid edge), because both the score test and collision are inclusive per SPEC
    §7/§3. The engine matches the SPEC literally (auditor: zero drift); making either boundary strict
    to close the measure-zero case would itself be a SPEC deviation, so it is logged as a SPEC question
    rather than silently edited. Practically unreachable in normal scrolling.
  - **MINOR-2 (accepted, deferred to Phase B)** — `advance()` clamps only the upper bound of realDelta
    (`min(realDelta, maxRealDelta)`), per SPEC §6.9. A negative realDelta (e.g. tab-resume clock
    glitch) could stall the accumulator. Hardening with a `max(0, …)` lower bound belongs with the
    Phase-B shell that computes realDelta from frame timestamps; kept spec-literal for Phase A.
  - **MINOR-3 (resolved)** — added `ScoringTests.testCrashingPipeDoesNotScore` to cover F3's practical
    guarantee (a body-crashing pipe crashes before/without scoring).

- Phase B–E scaffold (UNVERIFIED — written on Linux, never compiled/run):
  - Added `PipeBird/` (the iOS app) + `docs/PHASE_B_SPEC.md` (the just-in-time Phase-B spec, folding in
    PHASE_B_HAZARDS H1–H5 and SPEC §10). Render shell = SwiftUI `GameView` (holds ONE `GameScene` —
    H1) over a SpriteKit `GameScene` that drives `PipeBirdSimulation` and maps `state`→nodes with NO
    gameplay logic in the shell. Includes BirdNode (googly eyes/shocked face), PipeNode, Effects
    (score pop + crash poof), AudioEngine (+persisted mute), HighScoreStore (UserDefaults), and
    Phase-D meta behind `FeatureFlags` (Evil mode, GameCenterManager, StoreKit TipJar; the latter two
    default OFF, needing Apple/ASC setup). Xcode project is declarative via XcodeGen (`project.yml`);
    `make project` then `make app` on a Mac. Assets/Info.plist/PrivacyInfo bundled (final icon art +
    sound files are human-supplied).
  - This scaffold compiles ONLY on macOS + Xcode (SwiftUI/SpriteKit/GameKit/StoreKit). It is a head
    start for the Mac session, NOT verified: expect compile fixes, then work the Gate-B checklist in
    `docs/PHASE_B_SPEC.md §6`. The Phase-A `make gate` is unaffected (the app is outside PipeBirdCore).

## Human-only / ready-for (post-session, on a Mac) — see OPERATIONS_RUNBOOK §7
- Apple Developer account; code signing / provisioning; App Store Connect listing + screenshots;
  Game Center leaderboard creation; age rating; real-device testing; submission.
- All Phase B–E build/verification (SwiftUI/SpriteKit/SpriteView/GameKit/StoreKit, `make app` via
  `xcodebuild`, simulator smoke, 60fps checks) is deferred to macOS + Xcode.
