# Pipe Bird — Project Rules
*Advisory and always-loaded. Survives /compact (re-read from disk). Hard rules are enforced by hooks + `make gate`. Full detail lives in SPEC.md — this file stays tight on purpose.*

## Source of truth
- **SPEC.md** is authoritative for design + API + the `step()` contract. Read it at session start and after any /compact.
- **PROGRESS.md** is the ledger. Update it at every gate; mirror it with your TodoWrite list.
- Build-Playbook and the Phase-A narrative spec are rationale only; SPEC.md wins on any conflict.

## Commands (use these — never ad-hoc variants)
- `make test-nogolden` — fast iteration loop (skips the GoldenTrace until it's recorded).
- `make test` — full suite (includes GoldenTrace).
- `make gate` — the hard phase gate: format-check + build + full test + golden-frozen check. Non-zero = fail.
- `make record-golden` — prints the one-time GoldenTrace record steps.
- `make app` — `xcodebuild` the iOS app (Phase B+; needs macOS + Xcode).

## Hard invariants (see SPEC.md §2 for the full list — these are the ones you will be tempted to break)
- `PipeBirdCore` imports **no Apple-UI frameworks and no Foundation** in `Sources/`. Stdlib only.
- **All** logic (movement, collision, scoring, spawn, difficulty, RNG) lives in the core. The render shell holds none.
- **No `SKPhysicsBody`** for gameplay. **All randomness via `DeterministicRNG`.** Physics is **dt-based with a fixed sub-step.**
- No force-unwraps / unchecked indexing in the per-frame hot path.

## Evidence before claims (the cardinal rule)
- Never say tests pass / build works / a feature works without **fresh** command output you just ran. Cached results don't count.
- "Tests pass" means: you just ran `make test` (or `make gate`), read the exit code, and it was green.

## Gate protocol (every phase boundary)
1. Run `spec-auditor` and `hostile-reviewer` **in parallel** on the just-written files (name them explicitly). Resolve findings.
2. Run `test-runner` → it runs `make gate` and pastes fresh evidence. The gate is the hard line.
3. Only on PASS: update PROGRESS.md, then `git commit` a checkpoint.
4. Subagents start clean — always hand them file paths and point them at SPEC.md.

## Scope discipline
- Finish MUST-scope (SPEC.md §4.5) to a green ship audit **first**. If context tightens: finish MUST, run the final audit, **stop**. Never half-build COULD items.

## Phase 0 calibration (do this before scaffolding)
- Verify current subagent frontmatter, hook config, and the hook stdin/JSON shape against code.claude.com/docs. Adjust `.claude/` files if the schema has drifted. `chmod +x .claude/hooks/*.sh`. Ensure `jq` and `swiftformat` are installed.
