#!/bin/bash

set -euo pipefail

if [ "${1:-}" = "" ]; then
  echo "Usage: bash Cursor/scripts/bootstrap-cursor-project.sh /path/to/project"
  exit 1
fi

SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TARGET_PROJECT="$1"

if [ ! -d "$TARGET_PROJECT" ]; then
  echo "Target project does not exist: $TARGET_PROJECT"
  exit 1
fi

mkdir -p "$TARGET_PROJECT/.cursor/rules"
mkdir -p "$TARGET_PROJECT/.cursor/agents"
mkdir -p "$TARGET_PROJECT/.cursor/skills"
mkdir -p "$TARGET_PROJECT/.cursor/scripts"

cp "$SOURCE_ROOT"/Cursor/rules/*.md "$TARGET_PROJECT/.cursor/rules/"
cp "$SOURCE_ROOT"/Cursor/agents/*.md "$TARGET_PROJECT/.cursor/agents/"
cp -R "$SOURCE_ROOT"/Cursor/skills/* "$TARGET_PROJECT/.cursor/skills/"
cp "$SOURCE_ROOT"/Cursor/scripts/guard-bash-portable.sh "$TARGET_PROJECT/.cursor/scripts/guard-bash-portable.sh"
cp "$SOURCE_ROOT"/Cursor/scripts/gen-commit-message.sh "$TARGET_PROJECT/.cursor/scripts/gen-commit-message.sh"

chmod +x \
  "$TARGET_PROJECT/.cursor/scripts/guard-bash-portable.sh" \
  "$TARGET_PROJECT/.cursor/scripts/gen-commit-message.sh"

if [ -d "$TARGET_PROJECT/.git/hooks" ]; then
  cat > "$TARGET_PROJECT/.git/hooks/pre-commit" <<'EOF'
#!/bin/bash
set -euo pipefail
if [ -x ".cursor/scripts/guard-bash-portable.sh" ]; then
  exec ".cursor/scripts/guard-bash-portable.sh"
fi
exit 0
EOF
  chmod +x "$TARGET_PROJECT/.git/hooks/pre-commit"
fi

echo "Cursor bootstrap complete for: $TARGET_PROJECT"
echo "- Installed .cursor/rules"
echo "- Installed .cursor/agents"
echo "- Installed .cursor/skills"
echo "- Installed .cursor/scripts"
echo "- Installed .git/hooks/pre-commit (if git repo)"
