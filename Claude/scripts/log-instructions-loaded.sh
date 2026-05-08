#!/bin/bash
# InstructionsLoaded hook — append a one-line JSON event for every
# instruction-load event (CLAUDE.md / .claude/rules/*.md / CLAUDE.local.md).
#
# Read it with:
#   tail -f ~/.claude/logs/instructions-loaded.jsonl
#   cat ~/.claude/logs/instructions-loaded.jsonl | jq .
#
# Useful for debugging path-scoped rules: confirm a rule fired when you
# expected it to, or see why it didn't (paths didn't match, file wasn't
# discovered, etc.).

set -uo pipefail

INPUT=$(cat)
LOG_DIR="$HOME/.claude/logs"
LOG="$LOG_DIR/instructions-loaded.jsonl"
mkdir -p "$LOG_DIR"

TS=$(date '+%Y-%m-%dT%H:%M:%S%z')

# Append the harness-supplied JSON with a timestamp prepended.
# Falls back to a raw write if jq isn't available (shouldn't happen — jq is a setup prereq).
if command -v jq >/dev/null 2>&1; then
  printf '%s\n' "$INPUT" | jq -c --arg ts "$TS" '. + {ts: $ts}' >> "$LOG" 2>/dev/null \
    || printf '%s %s\n' "$TS" "$INPUT" >> "$LOG"
else
  printf '%s %s\n' "$TS" "$INPUT" >> "$LOG"
fi

exit 0
