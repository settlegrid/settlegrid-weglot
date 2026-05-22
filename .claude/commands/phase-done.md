---
description: Close out the current phase — verify the gate truly passed, checkpoint, and advance.
allowed-tools: Read, Edit, Bash
---
Close out the current phase:

1. Confirm the gate genuinely passed: run `make gate` now (fresh) — do not rely on a remembered result.
2. Confirm PROGRESS.md reflects reality (gate ticked, "Last green" timestamped, open issues current).
3. `git commit` a checkpoint if anything is uncommitted.
4. Advance "Current phase:" in PROGRESS.md to the next phase.
5. Decide context hygiene: if the working context is large or noisy, recommend starting a fresh session for the next phase (anchored by SPEC.md + PROGRESS.md) rather than continuing — quality degrades well before the context limit, and a clean per-phase context keeps the agent sharp.
6. State the next phase's first concrete action.

Refuse to advance if `make gate` is not green.
