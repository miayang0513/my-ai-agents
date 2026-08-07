# my-ai-agents

Claude-first personal AI-agent setup snapshot, with a Cursor alternative distribution for near-parity workflows.

## Start Here

- Primary (Claude): [`Claude/setup.md`](./Claude/setup.md)
- Alternative (Cursor): [`Cursor/setup.md`](./Cursor/setup.md)
- Claude reference: [`Claude/README.md`](./Claude/README.md)
- Cursor reference: [`Cursor/README.md`](./Cursor/README.md)
- Parity plan: [`NON_CLAUDE_PARITY_PLAN.md`](./NON_CLAUDE_PARITY_PLAN.md)
- Contributor/agent guardrails: [`AGENTS.md`](./AGENTS.md)

Setup and verification commands are intentionally centralized in edition-specific `setup.md` files.

## What's in `Claude/`

| Path | Purpose |
| --- | --- |
| [`Claude/CLAUDE.md`](./Claude/CLAUDE.md) | Global preferences and behavior policy |
| [`Claude/settings.json`](./Claude/settings.json) | Main config (hooks, plugins, status line) |
| `Claude/settings.local.json` | Machine-local permissions — gitignored, created per device by the bootstrap script |
| [`Claude/statusline.sh`](./Claude/statusline.sh) | Custom status line renderer |
| [`Claude/scripts/`](./Claude/scripts/) | Guard/sync/auto-commit/instruction logging scripts |
| [`Claude/agents/`](./Claude/agents/) | Role-based subagents |
| [`Claude/skills/`](./Claude/skills/) | Hand-written skills |
| [`Claude/rules/`](./Claude/rules/) | Path-scoped auto-loaded rules |
| [`Claude/setup.md`](./Claude/setup.md) | Complete setup guide |

## Claude Subagents

| Agent | Model | Read/Write | Use for |
| --- | --- | --- | --- |
| [`frontend-engineer`](./Claude/agents/frontend-engineer.md) | opus | RW | UI, styling, client-side state, performance, accessibility, Figma implementation |
| [`backend-engineer`](./Claude/agents/backend-engineer.md) | opus | RW | APIs, services, schemas, queries, migrations, auth/session, jobs |
| [`devops-engineer`](./Claude/agents/devops-engineer.md) | sonnet | RW | CI/CD, Docker, IaC, deployment configs, build tooling |
| [`product-manager`](./Claude/agents/product-manager.md) | sonnet | RW (no Bash) | PRDs, specs, user stories, release/status updates |
| [`uiux-designer`](./Claude/agents/uiux-designer.md) | sonnet | RW (no Bash) | Design review, design-system audits, Figma-to-spec translation |
| [`qa-engineer`](./Claude/agents/qa-engineer.md) | sonnet | RW | Test plans, bug repro, flaky-test triage, regression suites |
| [`code-reviewer`](./Claude/agents/code-reviewer.md) | opus | **read-only** | Cold-context review with severity-tagged findings |
| [`security-reviewer`](./Claude/agents/security-reviewer.md) | opus | **read-only** | Threat modeling, secret/dependency scanning, auth/input-validation review |

The four `sonnet` roles also set `effort: low`; `frontend-engineer` and `backend-engineer` set `background: false`.

## Claude Skills

| Skill | What it does |
| --- | --- |
| [`commit`](./Claude/skills/commit) | Inspects git state, drafts Conventional Commit messages, performs commit workflow on request |
| [`commit-for-review`](./Claude/skills/commit-for-review) | Same as `commit`, but lands the commit on a derived `review/<id>` branch to keep review changes off the branch under review |
| [`code-review`](./Claude/skills/code-review) | Reviews staged + unstaged work only, with findings/fix workflow |
| [`code-review-branch`](./Claude/skills/code-review-branch) | Reviews full branch vs base before PR/merge |
| [`skill-judge`](./Claude/skills/skill-judge) | Evaluates skill quality with rubric-based scoring |
| [`react`](./Claude/skills/react) | React client performance guidance (rerenders, bundle, waterfalls, hot paths) |
| [`nextjs`](./Claude/skills/nextjs) | Next.js App Router guidance (RSC boundaries, server caching, hydration, route strategy) |
| [`sync-device`](./Claude/skills/sync-device) | Pulls this repo onto a device, runs `bootstrap-claude.sh`, checks the per-device gaps the snapshot can't carry, and summarises what changed |

## Claude Rules

Rules in [`Claude/rules/`](./Claude/rules/) auto-load by path pattern and apply to both the main agent and subagents.

| Rule | Triggers on | Covers |
| --- | --- | --- |
| [`typescript`](./Claude/rules/typescript.md) | `**/*.{ts,tsx}` | strict typing, `satisfies`, boundary validation, predictable error envelopes |
| [`react`](./Claude/rules/react.md) | `**/*.{tsx,jsx}` | component patterns, measured memoization, effect hygiene, key stability |
| [`nextjs`](./Claude/rules/nextjs.md) | `app/**`, `pages/**`, `next.config.*`, `middleware.ts` | server-first defaults, dynamic markers, cache/revalidation hygiene |
| [`tailwind`](./Claude/rules/tailwind.md) | `**/*.{tsx,jsx}`, tailwind/global CSS | utility-first structure, semantic HTML, responsive layout conventions |
| [`node-lambda`](./Claude/rules/node-lambda.md) | `handlers/**`, `lambda/**`, `*.handler.{ts,js}`, etc. | Node LTS runtime patterns, AWS SDK v3, lazy init/cold-start hygiene |
| [`aws-cdk`](./Claude/rules/aws-cdk.md) | `cdk.json`, `bin/*.ts`, `lib/*-stack.ts`, `cdk/**`, `infra/**` | CDK v2 conventions, bundling patterns, resource tagging, safety checks |

## Claude Hooks

Configured under `hooks` in [`Claude/settings.json`](./Claude/settings.json). Hooks run automatically around tool usage and session lifecycle events.

| Event | Matcher | Script | What it does |
| --- | --- | --- | --- |
| `PreToolUse` | `Bash` | [`guard-bash.sh`](./Claude/scripts/guard-bash.sh) | Blocks destructive commands (`rm -rf`, `git push --force`, `git reset --hard`, `npm publish`, etc.) before execution. |
| `PostToolUse` | `Edit\|Write` | [`sync-to-snapshot.sh`](./Claude/scripts/sync-to-snapshot.sh) | After edits, mirrors whitelisted `~/.claude/` paths into `Claude/` in this repo, with a secret-pattern guard to avoid syncing risky content. |
| `Stop` (async) | — | [`auto-commit-snapshot.sh`](./Claude/scripts/auto-commit-snapshot.sh) | At session end, if snapshot files changed, drafts/validates a Conventional Commit message and attempts to commit automatically. |
| `InstructionsLoaded` | — | [`log-instructions-loaded.sh`](./Claude/scripts/log-instructions-loaded.sh) | Appends instruction-load events to `~/.claude/logs/instructions-loaded.jsonl` for rule/instruction debugging. |

The `PostToolUse` + `Stop` pairing keeps the snapshot self-maintaining over time.

## Claude Plugins

Defined in [`Claude/settings.json`](./Claude/settings.json):

| Plugin | Marketplace | What it gives you |
| --- | --- | --- |
| `skill-creator` | `claude-plugins-official` | **Disabled** — the hand-written skills in `Claude/skills/` cover the workflows that mattered |
| `document-skills` | `anthropic-agent-skills` | **Disabled** — its bundle duplicated built-in skills and pulled ~17 rarely-used ones into every session |
| `context7` | `claude-plugins-official` | **Disabled** — superseded by the Claude.ai-managed Context7 connector |
| `typescript-lsp` | `claude-plugins-official` | TypeScript Language Server diagnostics and symbol-aware navigation (requires `typescript-language-server` on `PATH`) |

## Cursor Alternative

For users who prefer Cursor, this repo includes a parallel distribution in [`Cursor/`](./Cursor/):

- rules, agents, skills, and scripts adapted for Cursor runtime conventions
- bootstrap flow for wiring a target project quickly
- setup details in [`Cursor/setup.md`](./Cursor/setup.md)

## Setup-Only Details

All operational steps are intentionally centralized in setup docs:

- Claude install/auth/bootstrap/MCP/plugins/checklist: [`Claude/setup.md`](./Claude/setup.md)
- Cursor bootstrap/MCP/checklist: [`Cursor/setup.md`](./Cursor/setup.md)

## License

Personal config — feel free to copy and adapt.
