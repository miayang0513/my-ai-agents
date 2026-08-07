#!/bin/bash
# Install this snapshot into ~/.claude/ on the current device.
#
# Replaces the manual `cp` sequence in setup.md §3, which was unsafe: the snapshot
# stores a literal $HOME token in settings.json (see sync-to-snapshot.sh) so that
# machines with different usernames don't ping-pong commits. Copying it verbatim
# would leave unexpandable paths inside single quotes and silently disable every
# externally-managed hook.
#
# Idempotent — re-run after pulling to update this device.
#
# Usage: bash Claude/scripts/bootstrap-claude.sh

set -euo pipefail

SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SNAPSHOT_DIR="$SOURCE_ROOT/Claude"
CLAUDE_DIR="$HOME/.claude"

[ -d "$SNAPSHOT_DIR" ] || { echo "Snapshot not found: $SNAPSHOT_DIR"; exit 1; }

mkdir -p "$CLAUDE_DIR"/{scripts,agents,skills,rules}

# settings.json — expand the $HOME token to this device's absolute path. The hook
# commands quote their paths with single quotes, so the shell will not expand the
# token at runtime; it has to be baked in here.
if [ -f "$CLAUDE_DIR/settings.json" ] && ! cmp -s \
    <(sed "s|\$HOME/|$HOME/|g" "$SNAPSHOT_DIR/settings.json") "$CLAUDE_DIR/settings.json"; then
  BACKUP="$CLAUDE_DIR/settings.json.bak-$(date '+%Y%m%d-%H%M%S')"
  cp "$CLAUDE_DIR/settings.json" "$BACKUP"
  echo "- Backed up existing settings.json -> $(basename "$BACKUP")"
fi
sed "s|\$HOME/|$HOME/|g" "$SNAPSHOT_DIR/settings.json" > "$CLAUDE_DIR/settings.json"
echo "- Installed settings.json (\$HOME expanded to $HOME)"

# settings.local.json — per-device permission allowlist, gitignored and never
# mirrored. Seed it once from the template if the device has none; never clobber.
if [ ! -f "$CLAUDE_DIR/settings.local.json" ]; then
  if [ -f "$SNAPSHOT_DIR/settings.local.json" ]; then
    cp "$SNAPSHOT_DIR/settings.local.json" "$CLAUDE_DIR/settings.local.json"
    echo "- Seeded settings.local.json from local template"
  else
    printf '{\n  "permissions": {\n    "allow": []\n  }\n}\n' > "$CLAUDE_DIR/settings.local.json"
    echo "- Created empty settings.local.json"
  fi
else
  echo "- Kept existing settings.local.json (per-device, not overwritten)"
fi

for f in CLAUDE.md statusline.sh; do
  cp "$SNAPSHOT_DIR/$f" "$CLAUDE_DIR/$f"
done

for d in scripts agents skills rules; do
  [ -d "$SNAPSHOT_DIR/$d" ] || continue
  cp -R "$SNAPSHOT_DIR/$d/." "$CLAUDE_DIR/$d/"
done

chmod +x "$CLAUDE_DIR/statusline.sh" "$CLAUDE_DIR"/scripts/*.sh

echo "- Installed CLAUDE.md, statusline.sh, scripts/, agents/, skills/, rules/"
echo
echo "Claude bootstrap complete for: $CLAUDE_DIR"
echo "Next: run /plugin inside a session to install the plugins listed in settings.json."
