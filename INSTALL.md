# CONTROL PLANE — INSTALL & ORIENTATION

Drop these into the repo root. Final layout:

```
repo/
├─ CLAUDE.md                      # always-loaded rules (tight; points to SPEC.md)
├─ SPEC.md                        # canonical source of truth (from the consolidation pass)
├─ PROGRESS.md                    # the ledger (gate-guard reads "Current phase:")
├─ Makefile                       # canonical commands: test / test-nogolden / gate / app / record-golden
├─ .gitignore
├─ .swiftformat                   # pinned → idempotent formatting (no hook thrash)
├─ .claude/
│  ├─ settings.json               # hooks + pre-approved commands
│  ├─ agents/
│  │  ├─ spec-auditor.md          # read-only drift vs SPEC.md
│  │  ├─ hostile-reviewer.md      # read-only adversarial bug hunt (Opus)
│  │  ├─ test-runner.md           # runs `make gate`, pastes fresh evidence (Bash)
│  │  └─ ios-researcher.md        # current Apple API lookups (web)
│  ├─ hooks/
│  │  ├─ on-edit.sh               # PostToolUse: format + fast tests on core edits
│  │  └─ gate-guard.sh            # Stop: ADVISORY nudge only (never blocks)
│  └─ artifacts/                  # gitignored; make writes test/build logs here
├─ PipeBirdCore/                  # Phase A package (created by the agent)
└─ PipeBird/                      # Phase B app (created later)
```

## Prerequisites
- **macOS + Xcode + command-line tools** for the app build/run (`make app`). The logic core (`make test`) needs only the **Swift toolchain** (works on Linux CI too).
- `swiftformat`, `jq`, and GNU/BSD `make` on PATH.

## One-time setup (Phase 0)
1. `chmod +x .claude/hooks/*.sh` (exec bit is not carried by the file transfer).
2. `git init` and commit the control plane as the first checkpoint.
3. **Verify schemas against code.claude.com/docs** — these are the items most likely to have drifted since authoring:
   - subagent frontmatter keys (`name`/`description`/`tools`/`model`) and `.claude/agents/` location;
   - hook event names (`PostToolUse`/`Stop`/`SessionStart`), the `matcher` key, and especially the **stdin JSON shape** the hook command receives (`on-edit.sh` extracts `file_path` defensively with `jq` — confirm the real key).
   Adjust the files if anything differs, then commit.
4. Run `/agents` to confirm all four subagents load. Trigger a no-op edit to confirm `on-edit.sh` fires.

## How the pieces enforce quality (and the honest limits)
- **Continuous:** `on-edit.sh` formats + runs fast core tests on every core Swift edit. Real, automatic.
- **Hard gate:** `make gate` (format-check + build + full test + GoldenTrace-frozen) — run by the `test-runner` subagent at each phase boundary. Non-zero exit = fail. This is the real, blocking enforcement.
- **Advisory only:** `gate-guard.sh` (Stop hook) never blocks; it just nudges if test evidence is stale or no commit exists. Per audit F8, do **not** treat a clean Stop as proof a gate passed — only `make gate` is proof.

## Workflow per phase
1. Iterate: `make test-nogolden` until green.
2. (Phase A only, once) `make record-golden` → freeze the GoldenTrace fixture.
3. Gate: invoke `spec-auditor` ∥ `hostile-reviewer` on the new files → resolve findings → `test-runner` runs `make gate`.
4. On PASS: update `PROGRESS.md`, `git commit` a checkpoint, advance the phase.
