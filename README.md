# PIPE BIRD — IMPLEMENTATION PACKAGE
*Everything an implementing Claude Code agent needs to build the game from Phase 0 to a fully-audited ship. This is laid out as the target repo: drop the contents at your repo root.*

## Quick start
1. **Confirm prerequisites:** macOS + Xcode + Swift toolchain + `swiftformat` + `jq` on PATH, and a plan defaulting to **Opus**.
2. **Confirm the one open decision:** the deployment target is pinned to **iOS 17+** (in `KICKOFF_PROMPT.md` / Phase B). Change it if you want a different floor (reach vs. modern APIs).
3. **Setup (one time):** from the repo root, `chmod +x .claude/hooks/*.sh`, then `git init`. (See `INSTALL.md` for the full Phase-0 checklist incl. verifying the `.claude/` schema against current docs.)
4. **Launch:** open Claude Code (Opus) at the repo root and paste the block inside `KICKOFF_PROMPT.md`. It self-detects work in progress and resumes, so the same block is safe to paste in any later session.

## What's here (and where it goes)
```
root/
  KICKOFF_PROMPT.md      ← paste this into Claude Code to start/resume
  INSTALL.md             ← placement + one-time setup + Phase-0 verification
  README.md              ← this file
  CLAUDE.md              ← always-loaded rules (tight; points to SPEC)
  SPEC.md                ← THE single canonical contract (game + API + step order)
  PROGRESS.md            ← the build ledger (gate status, decisions)
  OPERATIONS_RUNBOOK.md  ← context discipline, multi-session resume, ship-audit sweep
  TRACEABILITY_MATRIX.md ← every SPEC requirement → its test
  PHASE_B_HAZARDS.md     ← SpriteView/SwiftUI silent-bug list (read before Phase B)
  PrivacyInfo.xcprivacy  ← pre-filled (UserDefaults / CA92.1) → app target in Phase E
  Makefile               ← canonical commands (test / test-nogolden / gate / app / record-golden)
  .gitignore  .swiftformat
  .claude/
    settings.json        ← hooks + pre-approved commands
    agents/              ← spec-auditor, hostile-reviewer, test-runner, ios-researcher
    hooks/               ← on-edit.sh (format+fast tests), gate-guard.sh (advisory)
    commands/            ← /gate, /record-golden, /resume, /phase-done
  PipeBirdCore/Tests/PipeBirdCoreTests/
    TestSupport.swift                         ← shared fixtures
    DeterminismTests / CollisionBoundaryTests / FrameRateIndependenceTests / GoldenTraceTests.swift   ← PRE-WRITTEN (drop-in oracles)
    BirdDynamics / RNG / Spawning / Scoring / Difficulty / StateMachine / Event / Robustness Tests.swift   ← 8 STUBS (agent fills, currently XCTFail)
  docs/                  ← rationale & audits (NOT specs):
    BUILD_PLAYBOOK.md, CONSISTENCY_AUDIT.md, IMPLEMENTABILITY_AUDIT.md,
    REFERENCE_TESTS_ORCHESTRATION_GUIDE.md, STRATEGIC_BRIEF.md
```

## What the agent PRODUCES (not in this package — built during the session)
`PipeBirdCore/Package.swift` + `Sources/PipeBirdCore/*.swift` (the engine, per SPEC §6/§7), the `PipeBird` app target (SwiftUI + SpriteKit shell, Phase B+), app icon/launch assets (Phase E), and the recorded GoldenTrace fixture.

## Honest caveats (read these)
- **Nothing here has been compiled.** The tests are written against the SPEC API with no toolchain to check them. Phase A's first task is to get them compiling against a stub engine and reconcile any spec↔test mismatch *as a spec question, not a silent edit*. If the agent reports mismatches there, that's the package working — surfacing on-paper risk early.
- **`SPEC.md` is the only spec.** The standalone Phase-A spec was consolidated into it and is intentionally not included; `docs/` holds rationale/audits, not authority.
- **`.claude/` schema** (subagent frontmatter, hook config + stdin shape, slash-command format) is as-of-authoring — Phase 0 verifies it against code.claude.com/docs and adjusts if drifted.
- **Human-only steps** (not automatable): Apple Developer account, code signing/provisioning, App Store Connect listing + screenshots, Game Center leaderboard creation, age rating, real-device testing, submission. The build is produced *ready for* these; the agent prints them as a closing checklist.

## Provenance
Concept selected from a battletested shortlist (`docs/STRATEGIC_BRIEF.md`); orchestration rationale in `docs/BUILD_PLAYBOOK.md`; the spec was hardened by two audits (`docs/CONSISTENCY_AUDIT.md`, `docs/IMPLEMENTABILITY_AUDIT.md`) whose findings (F#/I#) are folded into `SPEC.md`.
