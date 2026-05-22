#!/usr/bin/env bash
# Stop hook — ADVISORY ONLY. Never blocks (always exits 0). Real, blocking enforcement is `make gate`
# (run by the test-runner at each phase boundary) plus the PostToolUse fast tests. This just nudges:
# it surfaces a reminder to stderr if, during a code phase, there's no fresh test log or recent commit.
# Resolves audit F8 without the footgun of blocking every turn-end.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)" || exit 0
cd "$ROOT" || exit 0

PROGRESS="$ROOT/PROGRESS.md"
TESTLOG="$ROOT/.claude/artifacts/last-test.log"
FRESH_SECS=900   # 15 min

phase="$(grep -m1 -i '^Current phase:' "$PROGRESS" 2>/dev/null | sed 's/.*: *//' | tr -d '[:space:]')"
# Phase 0 (setup) and unknown phases: nothing to nudge about.
case "$phase" in
  0*|"" ) exit 0 ;;
esac

notes=()

if [[ -f "$TESTLOG" ]]; then
  now=$(date +%s)
  mtime=$(stat -f %m "$TESTLOG" 2>/dev/null || stat -c %Y "$TESTLOG" 2>/dev/null || echo 0)
  if (( now - mtime > FRESH_SECS )); then
    notes+=("test log is stale ($((now - mtime))s old) — run 'make test' before claiming this phase done")
  fi
else
  notes+=("no test log yet — run 'make test' (writes .claude/artifacts/last-test.log)")
fi

if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  cage=$(( $(date +%s) - $(git -C "$ROOT" log -1 --format=%ct 2>/dev/null || echo "$(date +%s)") ))
  if (( cage > 3600 )); then
    notes+=("no git commit in the last hour — checkpoint completed work")
  fi
else
  notes+=("not a git repo — 'git init' and commit phase checkpoints")
fi

if (( ${#notes[@]} > 0 )); then
  {
    echo "gate-guard (advisory): before treating this phase as complete —"
    for n in "${notes[@]}"; do echo "  - $n"; done
    echo "  (the hard gate is 'make gate', run via the test-runner subagent)"
  } >&2
fi
exit 0
