# Cursor Edition

Cursor-first distribution of this repo with near-parity capabilities:

- `.cursor/rules`
- `.cursor/agents`
- `.cursor/skills`
- safety guard script + bootstrap scripts

## Quick start

See [`setup.md`](./setup.md) for the full flow.

```bash
git clone https://github.com/miayang0513/my-ai-agents.git ~/Repos/my-ai-agents
cd ~/Repos/my-ai-agents
bash Cursor/scripts/bootstrap-cursor-project.sh /path/to/your-project
```

## What's included

| Path | Purpose |
| --- | --- |
| [`rules/`](./rules/) | Path-scoped rules to copy into target project `.cursor/rules/` |
| [`agents/`](./agents/) | Cursor-ready role agent definitions |
| [`skills/`](./skills/) | Skill library for `.cursor/skills/` |
| [`scripts/bootstrap-cursor-project.sh`](./scripts/bootstrap-cursor-project.sh) | One-command project bootstrap |
| [`scripts/guard-bash-portable.sh`](./scripts/guard-bash-portable.sh) | Destructive-command guard for git hook usage |
| [`scripts/gen-commit-message.sh`](./scripts/gen-commit-message.sh) | AI-assisted conventional commit message generator |
| [`setup.md`](./setup.md) | Full setup and capability mapping |

## Notes

- This edition does not require Claude CLI.
- MCP is supported, but you may need to remap tool names in `.cursor/agents/` to your local server IDs.
- Claude plugin marketplace behavior is not 1:1 in Cursor; use local skills and Cursor-native integrations instead.
- The `sync-device` skill is deliberately not ported. It drives `bootstrap-claude.sh` and the `~/.claude/` snapshot sync loop, and Cursor has no `PostToolUse`/`Stop` hook equivalents — so there is no snapshot to sync and nothing for the skill to do. This edition installs per-project via `bootstrap-cursor-project.sh`; re-run it after a `git pull` to update a project.
- See the MCP install/verification checklist in [`setup.md`](./setup.md#mcp-setup-checklist-recommended).
- For Claude-native setup, use [`../Claude/README.md`](../Claude/README.md) and [`../Claude/setup.md`](../Claude/setup.md).
