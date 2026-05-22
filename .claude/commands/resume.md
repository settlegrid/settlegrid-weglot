---
description: Safely resume the build in a new session by establishing GROUND TRUTH before trusting anything.
allowed-tools: Read, Grep, Glob, Bash, Task
---
You are resuming a multi-session build. Prior session notes (including PROGRESS.md) are CLAIMS, not facts. Establish ground truth first — documented incidents show new sessions wrongly trusting a prior session's report instead of verifying the actual files.

Do this in order, reporting findings:
1. Read SPEC.md (the contract) and PROGRESS.md (the claimed state). Do not act on PROGRESS.md yet.
2. `git status` and `git log --oneline -5`. If the working tree is dirty, STOP and surface it — never build on top of unversioned changes (an overwrite can destroy them irrecoverably).
3. Run `make test-nogolden` (or `make gate` if PROGRESS claims a phase complete) to observe the REAL current state. The exit code is the truth, not the ledger.
4. Reconcile: if reality disagrees with PROGRESS.md, fix PROGRESS.md to match reality and note the discrepancy.
5. Only then state the actual current phase and the next concrete action, and proceed.

If anything is ambiguous, ask rather than assume.
