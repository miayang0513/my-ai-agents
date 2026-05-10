#!/bin/bash

set -euo pipefail

# Portable destructive-command guard for git hooks or manual checks.
# It validates staged shell scripts and commit message text for obvious
# destructive commands. It does not parse runtime command streams.

PATTERNS=(
  '\brm[[:space:]]+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r|--recursive[[:space:]]+--force|--force[[:space:]]+--recursive)'
  '\bgit[[:space:]]+push[[:space:]]+.*(-f\b|--force\b)'
  '\bgit[[:space:]]+reset[[:space:]]+--hard\b'
  '\bgit[[:space:]]+clean[[:space:]]+.*-[a-zA-Z]*f'
  '\bgit[[:space:]]+branch[[:space:]]+-D\b'
  '\bgit[[:space:]]+checkout[[:space:]]+--[[:space:]]+\.'
  '\b(npm|yarn|pnpm|bun)[[:space:]]+publish\b'
  '>[[:space:]]*/dev/(sda|nvme|disk)'
  '\bdd[[:space:]]+if=.*[[:space:]]+of=/dev/'
)

MATCH=0

STAGED_FILES="$(git diff --cached --name-only -- '*.sh' '*.bash' 2>/dev/null || true)"

if [ -n "$STAGED_FILES" ]; then
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if [ -f "$f" ]; then
      for pat in "${PATTERNS[@]}"; do
        if grep -iEq "$pat" "$f"; then
          echo "Blocked by guard-bash-portable: destructive pattern found in $f"
          echo "Pattern: $pat"
          MATCH=1
        fi
      done
    fi
  done <<< "$STAGED_FILES"
fi

if [ "$MATCH" -eq 1 ]; then
  echo "Commit blocked. Review and remove dangerous commands or tune guard patterns."
  exit 1
fi

exit 0
