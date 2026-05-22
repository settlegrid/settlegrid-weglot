---
description: Run the full phase gate ritual — parallel audits, hard test gate, checkpoint.
argument-hint: "[phase letter, e.g. A]"
allowed-tools: Read, Grep, Glob, Bash, Task
---
Run the gate ritual for phase $ARGUMENTS (or the current phase from PROGRESS.md if blank):

1. Invoke the `spec-auditor` and `hostile-reviewer` subagents IN PARALLEL on the files changed since the last checkpoint (use `git diff --name-only` to scope). Hand each the file paths and point them at SPEC.md.
2. Resolve every BLOCKER/MAJOR finding. Log any consciously-accepted finding in PROGRESS.md with a reason.
3. Invoke the `test-runner` subagent to run `make gate` and paste fresh evidence (exit code + GATE PASS/FAIL line).
4. Only on GATE PASS: tick the phase in PROGRESS.md, update "Last green", and `git commit` a checkpoint named "gate <phase> pass".
5. Report a one-line verdict. On FAIL, list the exact blockers and stop — do not advance the phase.

Never claim PASS without the test-runner's fresh evidence (CLAUDE.md cardinal rule).
