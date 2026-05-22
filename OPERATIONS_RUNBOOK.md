# OPERATIONS RUNBOOK — running the build without it rotting or losing work
*Grounded in documented Claude Code failure modes. The architecture (phased gates, file memory, subagents) resists rot; this runbook makes it survive long/multi-session reality.*

## 1. The context reality (do not trust the big window)
Usable quality degrades **well before** the advertised context limit — felt around 300–400K tokens, and multi-fact retrieval gets unreliable near the ceiling. Treat context as a scarce, decaying resource:
- **One phase ≈ one (near-fresh) context.** Anchor each phase on SPEC.md + PROGRESS.md, not on a giant running conversation. Prefer starting the next phase in a fresh session over carrying a bloated one.
- **Delegate verbose work** (repo search, large reads, audits) to subagents so the main thread stays high-signal.
- **Watch for rot signals:** re-suggesting rejected ideas, hedging, contradicting earlier decisions, errors you already fixed reappearing. When you see them, stop adding — reset.

## 2. Rewind, don't correct in place
A wrong decision you correct **stays in context forever** and accelerates rot. When the agent goes down a wrong path:
- **Rewind** the conversation to before the bad turn and re-prompt with a better instruction (incorporate what you learned), OR
- use **checkpoint revert** to roll back conversation + files together, OR
- in the worst case, start a fresh session and `/resume`.
Avoid long correct → acknowledge → re-fabricate loops; they burn tokens and degrade the model.

## 3. Never work on unversioned state
Documented incident: a long session **overwrote and permanently destroyed an unversioned file.** Therefore:
- `git commit` at every gate (checkpoints are recovery points).
- Before any large/destructive edit, ensure the target is committed.
- `/resume` refuses to build on a dirty tree for exactly this reason.

## 4. Multi-session reality (plan for it)
Session/usage limits can end a working window in ~90 minutes under heavy load, and peak-hour throttling happens. **Assume the build spans multiple sessions.** That's fine — the package is designed for it:
- State lives in files (SPEC/PROGRESS/git), not in the conversation.
- Each new session begins with `/resume` (ground-truth verification) — never trust the prior session's claims; verify with `git status` + `make gate`.
- Do a **dry-run resume once** early (start a throwaway second session, run `/resume`, confirm it reconstructs state correctly) so you trust the path before you depend on it.

## 5. Model & delegation
- Main orchestrator/implementer: **Opus**. Hostile-reviewer: **Opus** (it must catch subtle bugs). spec-auditor / test-runner / ios-researcher: **Sonnet**; drop to **Haiku** only for cheap mechanical exploration.
- Use hooks (not prompts) for anything that must always run. Prompts are advisory; hooks are deterministic.

## 6. SHIP-AUDIT ADDENDUM — Required-Reason-API sweep (prevents ITMS-91053 rejection)
Even with zero third-party SDKs, using a "required reason API" without declaring it in `PrivacyInfo.xcprivacy` gets the app **rejected** at review. Before the final ship verdict, sweep the app code for each and confirm it's declared in the manifest (or removed):
- [ ] **UserDefaults** (`NSPrivacyAccessedAPICategoryUserDefaults`) — **we use this** for high-score persistence. Declared with reason `CA92.1`. ✔ (see `PrivacyInfo.xcprivacy`)
- [ ] **File timestamp** (`…FileTimestamp`) — declare reason if any file-date API is used.
- [ ] **System boot time** (`…SystemBootTime`) — declare if `mach_absolute_time`/uptime is used (some timing code does).
- [ ] **Disk space** (`…DiskSpace`) — declare if free-space APIs are used.
Then verify Xcode's generated **Privacy Report** matches, and that the App Store **Privacy Nutrition Label** says "no data collected / no tracking" (true for this game). Have `ios-researcher` confirm the current reason codes at submission time.

## 7. Human-only steps (the agent cannot do these — print as a closing checklist)
Apple Developer account, signing/provisioning, App Store Connect listing + screenshots (must match the real app), Game Center leaderboard creation, age rating, real-device test, and submission. The build is produced *ready for* these; they happen after the session on a Mac.
