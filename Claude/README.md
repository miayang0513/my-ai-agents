# Claude Edition

Claude-first distribution of this repo: settings, subagents, skills, rules, hooks, and setup instructions.

## Quick start

See [`setup.md`](./setup.md) for full install/auth/bootstrap.

```bash
git clone https://github.com/miayang0513/my-ai-agents.git ~/Repos/my-ai-agents
cd ~/Repos/my-ai-agents/Claude
# then follow setup.md §3 to copy files into ~/.claude/
```

## What's included

| Path | Purpose |
| --- | --- |
| [`CLAUDE.md`](./CLAUDE.md) | Global preferences and behavior policy |
| [`settings.json`](./settings.json) | Main config (hooks, plugins, status line) |
| [`settings.local.json`](./settings.local.json) | Machine-local permissions |
| [`statusline.sh`](./statusline.sh) | Custom status line renderer |
| [`scripts/`](./scripts/) | Guard/sync/auto-commit/instruction logging scripts |
| [`agents/`](./agents/) | Role-based subagents |
| [`skills/`](./skills/) | Hand-written skills |
| [`rules/`](./rules/) | Path-scoped auto-loaded rules |
| [`setup.md`](./setup.md) | Complete setup guide |

## Notes

- This edition is optimized for users running Claude Code with `~/.claude/`.
- For Cursor users, use the dedicated [`../Cursor/README.md`](../Cursor/README.md) and [`../Cursor/setup.md`](../Cursor/setup.md).
