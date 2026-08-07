# Claude Edition

Claude-first distribution of this repo: settings, subagents, skills, rules, hooks, and setup instructions.

## Quick start

See [`setup.md`](./setup.md) for full install/auth/bootstrap. This README is an overview only.

## What's included

| Path | Purpose |
| --- | --- |
| [`CLAUDE.md`](./CLAUDE.md) | Global preferences and behavior policy |
| [`settings.json`](./settings.json) | Main config (hooks, plugins, status line) |
| `settings.local.json` | Machine-local permissions — gitignored, created per device by the bootstrap script |
| [`statusline.sh`](./statusline.sh) | Custom status line renderer |
| [`scripts/`](./scripts/) | Guard/sync/auto-commit/instruction logging scripts |
| [`agents/`](./agents/) | Role-based subagents |
| [`skills/`](./skills/) | Hand-written skills |
| [`rules/`](./rules/) | Path-scoped auto-loaded rules |
| [`setup.md`](./setup.md) | Complete setup guide |

## Subagents

| Agent | Model | Read/Write | Use for |
| --- | --- | --- | --- |
| [`frontend-engineer`](./agents/frontend-engineer.md) | opus | RW | UI, styling, client-side state, performance, accessibility, Figma implementation |
| [`backend-engineer`](./agents/backend-engineer.md) | opus | RW | APIs, services, schemas, queries, migrations, auth/session, jobs |
| [`devops-engineer`](./agents/devops-engineer.md) | sonnet | RW | CI/CD, Docker, IaC, deployment configs, build tooling |
| [`product-manager`](./agents/product-manager.md) | sonnet | RW (no Bash) | PRDs, specs, user stories, release/status updates |
| [`uiux-designer`](./agents/uiux-designer.md) | sonnet | RW (no Bash) | Design review, design-system audits, Figma-to-spec translation |
| [`qa-engineer`](./agents/qa-engineer.md) | sonnet | RW | Test plans, bug repro, flaky-test triage, regression suites |
| [`code-reviewer`](./agents/code-reviewer.md) | opus | **read-only** | Cold-context review with severity-tagged findings |
| [`security-reviewer`](./agents/security-reviewer.md) | opus | **read-only** | Threat modeling, secret/dependency scanning, auth/input-validation review |

The four `sonnet` roles also set `effort: low`; `frontend-engineer` and `backend-engineer` set `background: false`.

## Skills

| Skill | What it does |
| --- | --- |
| [`commit`](./skills/commit) | Inspects git state, drafts Conventional Commit messages, performs commit workflow on request |
| [`commit-for-review`](./skills/commit-for-review) | Same as `commit`, but lands the commit on a derived `review/<id>` branch to keep review changes off the branch under review |
| [`code-review`](./skills/code-review) | Reviews staged + unstaged work only, with findings/fix workflow |
| [`code-review-branch`](./skills/code-review-branch) | Reviews full branch vs base before PR/merge |
| [`skill-judge`](./skills/skill-judge) | Evaluates skill quality with rubric-based scoring |
| [`react`](./skills/react) | React client performance guidance (rerenders, bundle, waterfalls, hot paths) |
| [`nextjs`](./skills/nextjs) | Next.js App Router guidance (RSC boundaries, server caching, hydration, route strategy) |
| [`sync-device`](./skills/sync-device) | Pulls this repo onto a device, runs `bootstrap-claude.sh`, checks the per-device gaps the snapshot can't carry, and summarises what changed |

## Rules

Rules in [`rules/`](./rules/) auto-load by path pattern and apply to both the main agent and subagents.

| Rule | Triggers on | Covers |
| --- | --- | --- |
| [`typescript`](./rules/typescript.md) | `**/*.{ts,tsx}` | strict typing, `satisfies`, boundary validation, predictable error envelopes |
| [`react`](./rules/react.md) | `**/*.{tsx,jsx}` | component patterns, measured memoization, effect hygiene, key stability |
| [`nextjs`](./rules/nextjs.md) | `app/**`, `pages/**`, `next.config.*`, `middleware.ts` | server-first defaults, dynamic markers, cache/revalidation hygiene |
| [`tailwind`](./rules/tailwind.md) | `**/*.{tsx,jsx}`, tailwind/global CSS | utility-first structure, semantic HTML, responsive layout conventions |
| [`node-lambda`](./rules/node-lambda.md) | `handlers/**`, `lambda/**`, `*.handler.{ts,js}`, etc. | Node LTS runtime patterns, AWS SDK v3, lazy init/cold-start hygiene |
| [`aws-cdk`](./rules/aws-cdk.md) | `cdk.json`, `bin/*.ts`, `lib/*-stack.ts`, `cdk/**`, `infra/**` | CDK v2 conventions, bundling patterns, resource tagging, safety checks |

## Hooks at a glance

Configured under `hooks` in [`settings.json`](./settings.json). Hooks run automatically around tool usage and session lifecycle events.

| Event | Matcher | Script | What it does |
| --- | --- | --- | --- |
| `PreToolUse` | `Bash` | [`guard-bash.sh`](./scripts/guard-bash.sh) | Blocks destructive commands (`rm -rf`, `git push --force`, `git reset --hard`, `npm publish`, etc.) before execution. |
| `PostToolUse` | `Edit\|Write` | [`sync-to-snapshot.sh`](./scripts/sync-to-snapshot.sh) | After edits, mirrors whitelisted `~/.claude/` paths into `Claude/` in this repo, with a secret-pattern guard to avoid syncing risky content. |
| `Stop` (async) | — | [`auto-commit-snapshot.sh`](./scripts/auto-commit-snapshot.sh) | At session end, if snapshot files changed, drafts/validates a Conventional Commit message and attempts to commit automatically. |
| `InstructionsLoaded` | — | [`log-instructions-loaded.sh`](./scripts/log-instructions-loaded.sh) | Appends instruction-load events to `~/.claude/logs/instructions-loaded.jsonl` for rule/instruction debugging. |

The `PostToolUse` + `Stop` pairing keeps the snapshot self-maintaining over time.
For hook setup/troubleshooting workflow, see [`setup.md`](./setup.md#hooks).

## MCP and connectors

This setup uses Claude.ai-managed connectors (account-level) and local MCP servers (device-level).
For exact commands and troubleshooting, see [`setup.md`](./setup.md#4-advanced).

## Plugins used

Defined in [`settings.json`](./settings.json):

| Plugin | Marketplace | What it gives you |
| --- | --- | --- |
| `skill-creator` | `claude-plugins-official` | **Disabled** — the hand-written skills in `skills/` cover the workflows that mattered |
| `document-skills` | `anthropic-agent-skills` | **Disabled** — its bundle duplicated built-in skills and pulled ~17 rarely-used ones into every session |
| `context7` | `claude-plugins-official` | **Disabled** — superseded by the Claude.ai-managed Context7 connector |
| `typescript-lsp` | `claude-plugins-official` | TypeScript Language Server diagnostics and symbol-aware navigation (requires `typescript-language-server` on `PATH`) |

Install/update flow and marketplace commands are documented in [`setup.md`](./setup.md#plugins--skills).

## Setup-only details

All operational steps are intentionally centralized in [`setup.md`](./setup.md), including:

- prerequisites and CLI install
- authentication flow
- file copy/bootstrap commands
- MCP connector/server setup
- plugin install/update commands
- IDE integration and keybindings
- sanity-check checklist

## Notes

- This edition is optimized for users running Claude Code with `~/.claude/`.
- For Cursor users, use the dedicated [`../Cursor/README.md`](../Cursor/README.md) and [`../Cursor/setup.md`](../Cursor/setup.md).
