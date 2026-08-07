# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Read [`AGENTS.md`](./AGENTS.md) first — it holds the provider-neutral contract (source of truth, editing rules, parity expectations, documentation structure, validation checklist) and is not repeated here. This file covers only what is Claude-specific or non-obvious.

## What this repo is

Not an application — a **snapshot of a personal AI-agent configuration**, shipped as two editions of the same operating model:

- `Claude/` — payload deployed to `~/.claude/` on each device, and a mirror of it. Source of truth for policy, rules, and role intent.
- `Cursor/` — near-parity port for the Cursor runtime, installed into a target project's `.cursor/`.

Everything is Markdown and Bash. No package manager, no build, no test suite, no lockfile.

Three files named some variant of "CLAUDE.md" — don't confuse them:

| File | Role |
| --- | --- |
| `CLAUDE.md` (root, this file) | Guidance for working **on** this repo. Never deployed, never synced. |
| `Claude/CLAUDE.md` | Payload — the user's global preferences, deployed to `~/.claude/CLAUDE.md`. |
| `CLAUDE.local.md` (root, optional) | Device-specific repo notes. Gitignored. |

## The snapshot sync loop — read before editing anything under `Claude/`

`Claude/` is **downstream** of `~/.claude/`. Two hooks (wired in `Claude/settings.json`, running from `~/.claude/scripts/`) drive it:

1. `PostToolUse` on `Edit|Write` → `sync-to-snapshot.sh` copies the edited live `~/.claude/` file into `<repo>/Claude/`, if it is whitelisted (`CLAUDE.md`, `settings.json`, `statusline.sh`, `scripts/`, `agents/`, `skills/`, `rules/`) and passes a secret-pattern grep.
2. `Stop` (async) → `auto-commit-snapshot.sh` re-sweeps those same paths into the snapshot, then stages `Claude/` and auto-commits with a `claude --print --model haiku` generated message.

Consequences that will bite you:

- **Edits made directly to whitelisted files under `Claude/` in this repo get overwritten** by the end-of-session drift sweep, which copies the live `~/.claude/` version on top. To change those, edit the file under `~/.claude/` and let the hook mirror it in. Root docs and everything under `Cursor/` are ordinary repo files — edit them here.
- The auto-commit only fires if nothing is already staged, HEAD is attached, and no rebase/merge is in progress. It un-stages and bails when the generated message fails the Conventional Commit regex. It stages `Claude/` only, so untracked root files are never swept into a commit.
- Both scripts resolve the repo as `$HOME/Repos/my-ai-agents`, overridable per-device via `SNAPSHOT_REPO` in `~/.claude/.sync-config` (deliberately not snapshotted).
- Sync activity, blocks, and aborts land in `~/.claude/sync-to-snapshot.log`.

## Multi-device invariants

The repo is pulled onto more than one machine, each running the sync loop, so every writer must produce byte-identical output for identical intent. Two rules enforce that — breaking either causes both machines to auto-commit revert-of-each-other forever:

- **No absolute `/Users/<name>/` paths in the snapshot.** Externally-managed tooling (orca, which is installed on every device) rewrites `~/.claude/settings.json` with absolute paths. `sync-to-snapshot.sh` normalizes them to a literal `$HOME` token on the way in; `bootstrap-claude.sh` expands the token on the way out. The token sits inside single quotes in the hook commands, so it is **not** shell-expanded at runtime — a hand-copied `settings.json` silently disables every hook it names.
- **Per-device state is never committed.** `settings.local.json` (permission allowlist) is gitignored and excluded from both the whitelist and the sweep.

Deploy or update a device with `bash Claude/scripts/bootstrap-claude.sh` — never a manual `cp`.

## Commands

There is nothing to build. Verification is script-level:

```bash
bash -n Claude/scripts/*.sh Cursor/scripts/*.sh Claude/statusline.sh   # syntax check
jq -e . Claude/settings.json                                          # settings are valid JSON
grep -n '/Users/' Claude/settings.json || echo "no absolute paths"     # multi-device invariant
diff -rq Claude Cursor                                                 # parity delta between editions

# guard hook: must exit 2 (blocked) for a destructive command, 0 otherwise
printf '{"tool_input":{"command":"rm -rf /tmp/nope"}}' | bash Claude/scripts/guard-bash.sh; echo $?

# sync hook: feed it a hook-shaped payload for one live file
printf '{"tool_name":"Edit","tool_input":{"file_path":"'"$HOME"'/.claude/settings.json"}}' \
  | bash Claude/scripts/sync-to-snapshot.sh

bash Claude/scripts/bootstrap-claude.sh                                # install/update this device
bash Cursor/scripts/bootstrap-cursor-project.sh /path/to/project       # install Cursor edition
tail -f ~/.claude/sync-to-snapshot.log                                 # watch sync/commit outcomes
tail -f ~/.claude/logs/instructions-loaded.jsonl                       # debug which rules fired
```

End-to-end checklists live in `Claude/setup.md` §5 and `Cursor/setup.md` §6. `jq` is a hard dependency of `guard-bash.sh`, `sync-to-snapshot.sh`, `log-instructions-loaded.sh`, and `statusline.sh`.

## Parity model

`Claude/` leads; `Cursor/` follows semantically (`AGENTS.md` defines the obligation). Rules and skills are byte-identical across editions. Agents are **not** — `Claude/agents/` has taken substantive workflow changes (task-sizing step 1, conditional `MEMORY.md` reads/writes, non-reflexive Context7 and Playwright use) that were never ported, so the Cursor copies still carry the older unconditional-context-gathering loop. That is open parity debt; expect a content diff on top of these mechanical axes:

| Axis | `Claude/` | `Cursor/` |
| --- | --- | --- |
| Config root in prose | `~/.claude/...`, `.claude/agent-memory/` | `~/.cursor/...`, `.cursor/agent-memory/` |
| Figma MCP namespace | `mcp__figma-eatsy__*`, `mcp__figma-personal__*` | `mcp__figma__*` |
| `model:` | `opus` for frontend/backend/code-reviewer/security-reviewer; `sonnet` + `effort: low` for devops/product-manager/qa/uiux | `sonnet`, no `effort` |
| Execution-mode frontmatter (`background:`, `effort:`) | present | absent |
| Destructive-command guard | `guard-bash.sh` via `PreToolUse` hook | `guard-bash-portable.sh` via `pre-commit` git hook |
| Plugin-provided skills (`document-skills:*`) | referenced | dropped, or redirected to Context7 / provider docs |

Cursor has no `PostToolUse`/`InstructionsLoaded`/`Stop` equivalents, so it has no snapshot sync or auto-commit — that side uses git hooks and the `AI_COMMIT_CMD` adapter (`Cursor/scripts/gen-commit-message.sh`: prompt on stdin, one plain-text Conventional Commit line on stdout).

## File conventions

- **Rules** (`*/rules/*.md`): frontmatter is a `paths:` glob list; body is a terse bullet list of conventions, closing with the project-wins escape hatch. Rules auto-load for the main agent as well as subagents, so agent files must not restate them.
- **Agents** (`*/agents/*.md`): frontmatter `name`, `description` (trigger phrases plus explicit "do NOT use for" redirects), `tools`, `model`, `memory: project`, `color`, optional `skills`, optional execution-mode keys (`background`, `effort`). Read-only roles (`code-reviewer`, `security-reviewer`) omit `Edit`/`Write`; `product-manager` and `uiux-designer` omit `Bash`. Bodies follow a fixed 7-step "When invoked" loop, a take/hand-back scope contract, workflow defaults, and an output contract — keep that skeleton when editing.
- **Skills** (`*/skills/<name>/SKILL.md`): frontmatter `name`, `description`, often `disable-model-invocation: true` and a scoped `allowed-tools` list. Longer material goes in a sibling `references/` directory, not inline.

The README capability tables drift from the files they describe (agent `model:` values have been wrong more than once). Verify against frontmatter, and update the tables in both the root and edition README when you change an agent, skill, rule, hook, or plugin.

## Commits

Single-line Conventional Commits, no body, no trailers, matching `^(feat|fix|refactor|docs|chore|style|test|build|revert|perf|ci|security)(\(scope\))?: <lowercase>` — the auto-commit hook rejects anything else. Scopes in use: `hooks`, `scripts`, `settings`, `skills`, `agents`, `setup`.
