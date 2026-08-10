#!/bin/bash

set -euo pipefail

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Run this script inside a git repository."
  exit 1
fi

DIFFSTAT="$(git diff --cached --stat)"
DIFFBODY="$(git diff --cached | sed -n '1,300p')"
RECENT="$(git log -5 --format='%s')"

if [ -z "$DIFFSTAT" ]; then
  echo "No staged changes. Stage files first."
  exit 1
fi

PROMPT=$(cat <<EOF
Generate one conventional-commits message for the staged diff.

Recent style:
$RECENT

Format rules:
- Single line, <70 chars when possible
- <type>(<scope>): <lowercase description>
- Types: feat, fix, refactor, docs, chore, style, test, build, perf, ci, security
- Imperative mood, no trailing period
- Output only the message line

Stat:
$DIFFSTAT

Diff (truncated):
$DIFFBODY
EOF
)

if [ -z "${AI_COMMIT_CMD:-}" ]; then
  echo "AI_COMMIT_CMD is not set."
  echo "Example:"
  echo "  export AI_COMMIT_CMD='cursor-agent prompt --model gpt-5.5-medium --quiet'"
  exit 0
fi

MSG="$(
  printf '%s' "$PROMPT" \
    | eval "$AI_COMMIT_CMD" \
    | sed -n '1p' \
    | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
    | tr -d '`"'
)"

if [ -z "$MSG" ] || ! echo "$MSG" | grep -qE '^(feat|fix|refactor|docs|chore|style|test|build|revert|perf|ci|security)(\([a-z0-9_-]+(, ?[a-z0-9_-]+)*\))?: [a-z]'; then
  echo "Generated message failed validation:"
  echo "$MSG"
  exit 1
fi

echo "$MSG"
