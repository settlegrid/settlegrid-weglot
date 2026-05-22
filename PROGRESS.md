# Pipe Bird — Build Ledger

Current phase: 0
<!-- gate-guard.sh reads the "Current phase:" line above. Use 0 for setup, then A/B/C/D/E/FINAL. -->

## Gate status
- [ ] Gate 0 — control plane scaffolded, hooks load, subagents listed
- [ ] Gate A — logic core green (incl. frozen GoldenTrace)
- [ ] Gate B — render shell builds + simulator smoke
- [ ] Gate C — game feel, still 60fps
- [ ] Gate D — meta (flags ON and OFF both run)
- [ ] Gate E — ship assets, Release build
- [ ] FINAL — end-to-end ship audit → SHIP-READY

## Last green
- Core test: (none yet)
- App build: (none yet)

## Open issues
- (none yet)

## Decisions / accepted-risks log
- Carried from CONSISTENCY_AUDIT.md:
  - **F7** — `FrameRateIndependenceTests.testEngineStep_dtScaling_isConsistent` ships intentionally weak; **strengthen or replace during Phase A** against the live API before Gate A.
  - **F8** — Stop-hook (`gate-guard.sh`) is **advisory and never blocks**. Real, blocking enforcement is `make gate` (run by `test-runner` at each gate) + the PostToolUse fast tests. Do not treat a clean Stop as proof of a passed gate.
- (add new decisions here; log every GoldenTrace re-record)
