#!/usr/bin/env bash
# PostToolUse hook. Runs swiftformat + fast tests ONLY when a PipeBirdCore Swift file changed.
# Reads the tool payload as JSON on stdin and extracts any file_path. The exact JSON shape can
# vary by Claude Code version — VERIFY in Phase 0 (the `..|.file_path?` walk is defensive).
# Always exits 0 (never blocks an edit). Requires: jq, swiftformat, make.
set -uo pipefail

input="$(cat 2>/dev/null || true)"
paths="$(printf '%s' "$input" | jq -r '..|.file_path? // empty' 2>/dev/null || true)"

if printf '%s\n' "$paths" | grep -q 'PipeBirdCore/.*\.swift'; then
  swiftformat PipeBirdCore >/dev/null 2>&1 || true
  echo "--- on-edit: core changed, running fast tests ---"
  make test-nogolden 2>&1 | tail -15 || true
fi
exit 0
