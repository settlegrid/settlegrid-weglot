---
description: Freeze the GoldenTrace fixture (one time, after all other Phase-A tests are green).
allowed-tools: Read, Edit, Bash
---
Freeze the golden trace. Preconditions: every test EXCEPT GoldenTrace is green (`make test-nogolden` passes). If not, stop and say so.

Steps:
1. In `PipeBirdCore/Tests/PipeBirdCoreTests/GoldenTraceTests.swift`, set `recordMode = true`.
2. Run `cd PipeBirdCore && swift test --filter GoldenTraceTests` — it prints a paste-ready `goldenCheckpoints` array and fails on purpose.
3. Paste the printed array into `goldenCheckpoints`, set `recordMode = false`.
4. Run `make test` (full suite, now including GoldenTrace) — confirm green with fresh evidence.
5. Log the record in PROGRESS.md decisions, and `git commit` "freeze golden trace".

Do not edit the fixture again unless an intended, reviewed tuning change requires re-recording (and log that too).
