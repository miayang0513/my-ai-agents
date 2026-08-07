#!/bin/bash
# PostToolUse hook — mirror whitelisted ~/.claude/ config files into the
# my-ai-agents snapshot repo so other devices can bootstrap from it.
#
# Mirror-only: never auto-commits. User reviews `git status` and commits manually.
# Secret guard: refuses to mirror files containing secret-looking patterns,
# logs the skip to ~/.claude/sync-to-snapshot.log instead.

set -uo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[ -z "$FILE_PATH" ] && exit 0

# Path resolution. Defaults assume ~/Repos/my-ai-agents; override per-device by
# creating ~/.claude/.sync-config with: SNAPSHOT_REPO="/your/path/to/my-ai-agents"
CLAUDE_DIR="$HOME/.claude"
SNAPSHOT_REPO="$HOME/Repos/my-ai-agents"
[ -f "$CLAUDE_DIR/.sync-config" ] && . "$CLAUDE_DIR/.sync-config"
SNAPSHOT_DIR="$SNAPSHOT_REPO/Claude"
LOG="$CLAUDE_DIR/sync-to-snapshot.log"

# Only operate on files under ~/.claude/
case "$FILE_PATH" in
  "$CLAUDE_DIR"/*) ;;
  *) exit 0 ;;
esac

REL="${FILE_PATH#$CLAUDE_DIR/}"

# Whitelist: top-level config + specific subdirs. Anything else (cache/, sessions/,
# projects/, plugins/, history.jsonl, etc.) is ignored.
#
# settings.local.json is deliberately NOT here: it holds the per-device permission
# allowlist, which each machine accumulates on its own. Mirroring it would make two
# machines overwrite each other's permissions on every sync. It is gitignored.
case "$REL" in
  CLAUDE.md|settings.json|statusline.sh) ;;
  scripts/*|agents/*|skills/*|rules/*) ;;
  *) exit 0 ;;
esac

# Secret guard: scan source for high-confidence secret signatures.
# False positives are preferred over leaks — when in doubt, skip + log.
if [ -f "$FILE_PATH" ] && grep -qiE \
  -e 'sk-[a-zA-Z0-9_-]{20,}' \
  -e 'fc-[a-f0-9]{20,}' \
  -e 'ghp_[a-zA-Z0-9]{20,}' \
  -e 'github_pat_[a-zA-Z0-9_]{20,}' \
  -e 'xox[bpas]-[a-zA-Z0-9-]{20,}' \
  -e 'AKIA[A-Z0-9]{16}' \
  -e 'AIza[0-9A-Za-z_-]{35}' \
  -e 'eyJ[a-zA-Z0-9_-]{20,}\.[a-zA-Z0-9_-]{20,}\.[a-zA-Z0-9_-]{20,}' \
  -e '-----BEGIN [A-Z ]*PRIVATE KEY-----' \
  -e '(api[_-]?key|secret|password|token|bearer)["'\'']?\s*[:=]\s*["'\''][^"'\'' ]{16,}' \
  "$FILE_PATH"; then
  printf '%s [BLOCKED] %s contains potential secret — not mirrored\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$FILE_PATH" >> "$LOG"
  exit 0
fi

DEST="$SNAPSHOT_DIR/$REL"
mkdir -p "$(dirname "$DEST")"

# settings.json is rewritten by external tooling (orca) that bakes in absolute
# /Users/<name>/ paths. Store a literal $HOME token in the snapshot instead, so a
# machine whose username differs doesn't see a diff and auto-commit a path swap on
# every session — two devices would otherwise ping-pong commits forever.
# bootstrap-claude.sh expands the token back on the way out.
case "$REL" in
  settings.json)
    sed 's|/Users/[^/"]*/|$HOME/|g' "$FILE_PATH" > "$DEST"
    ;;
  *)
    cp "$FILE_PATH" "$DEST"
    ;;
esac
exit 0
