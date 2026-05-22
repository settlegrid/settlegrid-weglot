# KICK-OFF PROMPT — Pipe Bird build

**How to use:** place the package files into the repo per `INSTALL.md` (control plane at root + `.claude/`; the pre-written tests + `TestSupport.swift` + the 8 stubs into `PipeBirdCore/Tests/PipeBirdCoreTests/`; `TRACEABILITY_MATRIX.md`, `OPERATIONS_RUNBOOK.md`, `PHASE_B_HAZARDS.md`, the audits, and `PrivacyInfo.xcprivacy` at root). Open Claude Code (**Opus**) at the repo root and paste the block below. It is safe to paste in a **fresh session too** — it self-detects work in progress and resumes via ground-truth verification.

---

```
MISSION
You are the implementing + orchestrating agent for "Pipe Bird," a native iOS game (SwiftUI + SpriteKit, with a pure Swift logic core). Build it end-to-end — from Phase 0 (scaffold) to a fully-audited SHIP-READY verdict — in this session, or across multiple sessions if you hit usage limits. Run on Opus. The repo already contains the full specification, control plane, and pre-written tests. Execute the plan they define; do not redesign it.

STEP 0 — ORIENT (before any action; use PLAN MODE)
Read these, in order, and treat them as binding:
  1. ./CLAUDE.md — always-on rules (also auto-loaded).
  2. ./SPEC.md — the canonical contract for PipeBirdCore + game design. This is the ONLY spec; audit findings (tagged F#/I#) are already folded in.
  3. ./OPERATIONS_RUNBOOK.md — context discipline, multi-session resume, model/delegation, and the ship-audit required-reason-API sweep.
  4. ./PROGRESS.md — ledger of current state.
  5. ./TRACEABILITY_MATRIX.md — every SPEC requirement → its test (your coverage checklist).

RESUME CHECK (critical): if PROGRESS.md shows any phase already started, DO NOT restart — run /resume to establish ground truth (git status + make gate) before trusting the ledger, then continue from the real current phase. Verify state with commands, not prose; never trust a prior session's claims.

CARDINAL RULES (non-negotiable)
  • Evidence before claims: never say a build/test/feature works without FRESH command output you just ran. "Tests pass" = you just ran `make test`/`make gate`, read the exit code, green.
  • Architecture law: PipeBirdCore imports no Apple-UI frameworks and no Foundation; ALL logic (movement/collision/scoring/spawn/difficulty) lives in the core; no SKPhysicsBody; physics is dt-based with a fixed sub-step; the rng param stays threaded but is UNCONSUMED in MUST scope — do not invent randomness. The render shell holds NO logic.
  • Scope discipline: finish MUST scope to a green ship audit FIRST. If context degrades or a limit nears, checkpoint and stop cleanly — never half-build COULD items.

GATE RITUAL (every phase boundary) — use the slash commands; invoke subagents BY NAME (they start clean: hand them file paths and point them at SPEC.md):
  • Iterate with `make test-nogolden`.
  • Run `/gate <phase>`: spec-auditor ∥ hostile-reviewer (parallel, on changed files) → resolve every BLOCKER/MAJOR → test-runner runs `make gate` and pastes fresh evidence.
  • On PASS: `/phase-done` (re-verify the gate is green, update PROGRESS.md, git commit a checkpoint, advance). On FAIL: list blockers, fix, re-gate. NEVER advance on a non-green gate.

PHASES
  Phase 0 — Calibrate & scaffold: verify the .claude/ schema (subagent frontmatter, hook config, hook stdin JSON shape, slash-command format) against code.claude.com/docs and adjust if drifted; `chmod +x .claude/hooks/*.sh`; confirm jq + swiftformat present; `git init` + first commit; run /agents to confirm all four load; make a trivial edit to confirm the hooks are wired (on-edit.sh will no-op until PipeBirdCore exists — that is expected).
  Phase A — Logic core (MOST IMPORTANT): create the PipeBirdCore SwiftPM package per SPEC §1/§6. Ensure the pre-written tests + TestSupport.swift + the 8 stub files live in Tests/PipeBirdCoreTests/. FIRST get them compiling against a stub engine — reconcile any spec↔test mismatch as a SPEC question, not a silent edit. Implement the engine to satisfy SPEC §6/§7 exactly. Fill every stub (XCTFail → real assertions per the matrix) — there are 8 stub files, INCLUDING BirdDynamicsTests — and strengthen the F7 weak test. Then `/record-golden` to freeze the trace. `/gate A`.
  Phase B — Render shell: read ./PHASE_B_HAZARDS.md FIRST. Create the PipeBird app (SwiftUI lifecycle) depending on the local core; SpriteView hosts ONE SKScene that reads touch → simulation.advance → syncs nodes. No logic in the shell. Obey H1–H5 (stable scene instance; reset lastUpdateTime on resume; pause + persist on background; touch→world mapping; ProMotion). Target **iOS 17+** (confirmed default — it gates SpriteView ergonomics, StoreKit 2, and GameKit; the core SwiftPM package can stay platform-agnostic). Use a placeholder bundle id `com.<owner>.pipebird` and product/scheme name **PipeBird** (matches the Makefile and PrivacyInfo); the final bundle id is tied to the Apple account (human-only). `make app` + simulator smoke. `/gate B`.
  Phase C — Game feel (SHOULD): eyes/faces/crash poof, ready/playing/crashed screens, instant restart, optional Evil mode. Stay 60fps. `/gate C`.
  Phase D — Meta: local high score + mute (SHOULD); Game Center + StoreKit tip jar (COULD) behind flags that degrade gracefully. Use the ios-researcher subagent for current Apple API specifics. App must run with flags ON and OFF. `/gate D`.
  Phase E — Ship assets: app icon set, launch screen, Info.plist usage strings (only what's actually used), add ./PrivacyInfo.xcprivacy to the app target, bundle id/version/build. Release-config build. `/gate E`.
  FINAL — End-to-end ship audit: spec-auditor (whole codebase) ∥ hostile-reviewer (whole codebase). test-runner: `make gate` + `xcodebuild` Debug AND Release + simulator smoke (start → steer → pass pipes → betray → crash → restart) + 60/120fps check. Run the OPERATIONS_RUNBOOK §6 required-reason-API sweep (UserDefaults MUST be declared — see PrivacyInfo.xcprivacy). Complete the ship checklist. Emit ONE verdict line: SHIP-READY or NOT-READY (with exact blockers).

CANNOT DO (human-only — produce "ready-for", then print as a closing checklist): Apple Developer account, code signing/provisioning, App Store Connect listing + screenshots, Game Center leaderboard creation, age rating, real-device testing, submission.

MULTI-SESSION: state lives in files (SPEC/PROGRESS/git), not this conversation. If you near a usage limit or notice context degradation (per OPERATIONS_RUNBOOK), run `/phase-done` (or at minimum commit + update PROGRESS), then tell me to start a fresh session and run /resume. Prefer a fresh context per phase.

BEGIN: enter PLAN MODE. Read CLAUDE.md, SPEC.md, OPERATIONS_RUNBOOK.md, PROGRESS.md (run /resume FIRST if PROGRESS shows work in progress). Present your Phase 0 plan, then on my "go" proceed autonomously through the phases, pausing only for a blocking ambiguity or a human-only step.
```

---

**Notes for you (not part of the prompt):**
- Confirm the two prerequisites before pasting: a **macOS + Xcode + Swift + swiftformat + jq** environment, and that you're on a plan defaulting to **Opus**.
- **One open decision to sign off:** the prompt pins **iOS 17+** as the deployment target. That's a modern-API-vs-device-reach tradeoff — iOS 17+ keeps SpriteView/StoreKit 2/GameKit clean; lowering it (e.g., iOS 16) widens reach but may complicate a few APIs. Change the "Target iOS 17+" line if you want a different floor.
- The first real signal of trouble is **Phase A's first compile** (spec↔test reconciliation). If the agent reports mismatches there, that's the package working as designed — it's surfacing exactly what couldn't be verified on paper.
- The prompt deliberately makes the agent **wait for your "go"** after the Phase 0 plan, then run autonomously with the gates as control points. If you'd rather it pause after *every* phase instead, change the last line to "pause after each `/phase-done` for my confirmation."
