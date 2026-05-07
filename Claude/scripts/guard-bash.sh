#!/bin/bash
# PreToolUse hook for Bash — blocks destructive commands.
# Wired in ~/.claude/settings.json under hooks.PreToolUse with matcher "Bash".
#
# Receives the Claude Code hook JSON on stdin; the bash command is at
# `.tool_input.command`.
#
# Behavior:
#   exit 0  → allow the command
#   exit 2  → block the command and surface the stderr message to Claude
#
# To bypass for a one-off case, run the command yourself in chat with the
# `!<command>` prefix, or temporarily comment out the hook in settings.json.

set -uo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# No command → nothing to validate.
[ -z "$COMMAND" ] && exit 0

# Denylist of regex patterns. Add or remove freely.
# Each entry is a POSIX extended regex matched case-insensitively.
PATTERNS=(
  # Filesystem destruction
  '\brm[[:space:]]+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r|--recursive[[:space:]]+--force|--force[[:space:]]+--recursive)'
  # Git history rewriting / force pushing
  '\bgit[[:space:]]+push[[:space:]]+.*(-f\b|--force\b)'
  '\bgit[[:space:]]+reset[[:space:]]+--hard\b'
  '\bgit[[:space:]]+clean[[:space:]]+.*-[a-zA-Z]*f'
  '\bgit[[:space:]]+branch[[:space:]]+-D\b'
  '\bgit[[:space:]]+checkout[[:space:]]+--[[:space:]]+\.'
  # Package publishing
  '\b(npm|yarn|pnpm|bun)[[:space:]]+publish\b'
  # Disk-level danger
  '>[[:space:]]*/dev/(sda|nvme|disk)'
  '\bdd[[:space:]]+if=.*[[:space:]]+of=/dev/'
)

for pat in "${PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -iEq "$pat"; then
    cat >&2 <<EOF
Blocked by ~/.claude/scripts/guard-bash.sh — command matches a destructive pattern:
  $COMMAND

Pattern matched: $pat

If you genuinely need to run this:
  1. Run it yourself in chat with the !<command> prefix, OR
  2. Edit the PATTERNS list in ~/.claude/scripts/guard-bash.sh.
EOF
    exit 2
  fi
done

exit 0
