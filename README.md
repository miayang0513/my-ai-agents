# my-ai-agents

A snapshot of my personal [Claude Code](https://docs.claude.com/en/docs/claude-code) configuration — settings, custom subagents, hand-written skills, hooks, and a from-zero setup guide. Drop the `Claude/` directory onto a fresh machine and you've got my full setup.

## Quick start

See [`Claude/setup.md`](./Claude/setup.md) for the full walkthrough — install, auth, copying the snapshot into `~/.claude/`, MCP servers, plugins, hooks, and subagents.

```bash
git clone https://github.com/miayang0513/my-ai-agents.git ~/Repos/my-ai-agents
cd ~/Repos/my-ai-agents/Claude
# then follow setup.md §3 to copy files into ~/.claude/
```

## What's in `Claude/`

| Path | Purpose |
| --- | --- |
| [`CLAUDE.md`](./Claude/CLAUDE.md) | Global preferences (think before coding, simplicity first, surgical changes, goal-driven execution) |
| [`settings.json`](./Claude/settings.json) | Main config — theme, status line, enabled plugins, known marketplaces, PreToolUse Bash guard |
| [`settings.local.json`](./Claude/settings.local.json) | Machine-local permission allowlist |
| [`statusline.sh`](./Claude/statusline.sh) | Custom status line wired up in `settings.json` |
| [`scripts/`](./Claude/scripts) | `guard-bash.sh` (destructive-command blocker), `sync-to-snapshot.sh` + `auto-commit-snapshot.sh` (auto-mirror `~/.claude/` back into this repo) |
| [`agents/`](./Claude/agents) | Custom role-based subagents — see below |
| [`skills/`](./Claude/skills) | Hand-written skills — see below |
| [`rules/`](./Claude/rules) | Path-scoped rules that auto-load when matching files are open — see below |
| [`setup.md`](./Claude/setup.md) | The full setup guide |

## Subagents

| Agent | Model | Read/Write | Use for |
| --- | --- | --- | --- |
| [`frontend-engineer`](./Claude/agents/frontend-engineer.md) | sonnet | RW | UI, styling, client-side state, perf, a11y, Figma |
| [`backend-engineer`](./Claude/agents/backend-engineer.md) | sonnet | RW | APIs, services, schemas, queries, migrations, auth, jobs |
| [`devops-engineer`](./Claude/agents/devops-engineer.md) | sonnet | RW | CI/CD, Docker, IaC, deployment configs, build tooling |
| [`product-manager`](./Claude/agents/product-manager.md) | sonnet | RW (no Bash) | PRDs, specs, user stories, status updates |
| [`uiux-designer`](./Claude/agents/uiux-designer.md) | sonnet | RW (no Bash) | Design review, design-system audits, Figma-to-spec |
| [`qa-engineer`](./Claude/agents/qa-engineer.md) | sonnet | RW | Test plans, bug repros, e2e tests, coverage analysis |
| [`code-reviewer`](./Claude/agents/code-reviewer.md) | sonnet | **read-only** | Cold-context code review producing severity-tagged findings |
| [`security-reviewer`](./Claude/agents/security-reviewer.md) | **opus** | **read-only** | Security review, threat modeling, secret/dep scanning |

## Skills

| Skill | What it does |
| --- | --- |
| [`commit`](./Claude/skills/commit) | Inspect git changes, draft a Conventional Commit message, create the commit on request |
| [`code-review`](./Claude/skills/code-review) | Review pending uncommitted work; supports findings-only mode |
| [`code-review-branch`](./Claude/skills/code-review-branch) | Pre-PR full-branch audit vs base; supports findings-only mode |
| [`skill-judge`](./Claude/skills/skill-judge) | Score a skill against an 8-dimension rubric (120 points) |
| [`react`](./Claude/skills/react) | Client-side React perf rules + decision flow + spot-and-fix recipes |
| [`nextjs`](./Claude/skills/nextjs) | Next.js App Router perf (server components, caching, RSC, hydration) |

## Rules

Path-scoped instructions that auto-load when Claude opens matching files (no need to invoke them — they apply to the main agent and subagents alike). Topic-per-file, tightly globbed.

| Rule | Triggers on | Covers |
| --- | --- | --- |
| [`typescript`](./Claude/rules/typescript.md) | `**/*.{ts,tsx}` | No `any`, prefer `type`, `satisfies`, generic constraints, boundary validation, error envelopes |
| [`react`](./Claude/rules/react.md) | `**/*.{tsx,jsx}` | Function components, no `useEffect` for fetching, React 19 actions, measured `useMemo`, stable keys |
| [`nextjs`](./Claude/rules/nextjs.md) | `app/**`, `pages/**`, `next.config.*`, `middleware.ts` | Server Components by default, Server Actions, dynamic markers, `next/*` primitives, cache hygiene |
| [`tailwind`](./Claude/rules/tailwind.md) | `**/*.{tsx,jsx}`, tailwind/global CSS | Mobile-first, logical properties, `clsx`/`cva`, no `@apply` outside CSS, semantic HTML |
| [`node-lambda`](./Claude/rules/node-lambda.md) | `handlers/**`, `lambda/**`, `*.handler.{ts,js}`, etc. | Node LTS, AWS SDK v3, connection reuse, lazy init, cold-start hygiene |
| [`aws-cdk`](./Claude/rules/aws-cdk.md) | `cdk.json`, `bin/*.ts`, `lib/*-stack.ts`, `cdk/**`, `infra/**` | CDK v2, no hardcoded names, `NodejsFunction` bundling, tag stateful resources, `cdk-nag` |

## Hooks

Wired up under `hooks` in [`settings.json`](./Claude/settings.json). Hooks run automatically around tool calls and session lifecycle events — they enforce behaviors Claude itself can't guarantee between turns.

| Event | Matcher | Script | What it does |
| --- | --- | --- | --- |
| `PreToolUse` | `Bash` | [`guard-bash.sh`](./Claude/scripts/guard-bash.sh) | Blocks destructive commands (`rm -rf`, `git push --force`, `git reset --hard`, `npm publish`, …) **before** they execute, regardless of which agent invoked them. Edit the `PATTERNS` array to tune the denylist. |
| `PostToolUse` | `Edit\|Write` | [`sync-to-snapshot.sh`](./Claude/scripts/sync-to-snapshot.sh) | After every file edit, mirrors whitelisted paths under `~/.claude/` (CLAUDE.md, settings\*.json, statusline.sh, scripts/, agents/, skills/) into `Claude/` in this repo so the snapshot stays in sync. Has a secret-guard regex to skip files that look like they contain credentials. |
| `Stop` (async) | — | [`auto-commit-snapshot.sh`](./Claude/scripts/auto-commit-snapshot.sh) | At session end, if `Claude/` has unstaged changes, drafts a Conventional Commit message via `claude --print --no-session-persistence --model haiku`, validates the format, and creates the commit. If the generated message fails validation it un-stages and leaves the work for the user; if `git commit` itself fails it logs and exits without rollback. Recursion-guarded with `CLAUDE_AUTOCOMMIT_RUNNING`. |

Together, the `PostToolUse` + `Stop` pair makes the snapshot self-maintaining: edit `~/.claude/` files in any session and they auto-mirror + auto-commit into this repo without manual `cp` / `git` work.

See [`setup.md` §4 → Hooks](./Claude/setup.md#hooks) for the broader hook system (events, configuration syntax, troubleshooting).

## Plugins

Installed via `/plugin` from the marketplaces declared in [`settings.json`](./Claude/settings.json) → `extraKnownMarketplaces`. See [`setup.md` §4 → Plugins & Skills](./Claude/setup.md#plugins--skills) for the install walkthrough.

| Plugin | Marketplace | What it gives you |
| --- | --- | --- |
| `skill-creator` | `claude-plugins-official` | Build / iterate on custom skills |
| `document-skills` | `anthropic-agent-skills` | ~17 skills: `docx`, `pdf`, `pptx`, `xlsx`, `frontend-design`, `web-artifacts-builder`, `theme-factory`, `webapp-testing`, `internal-comms`, `brand-guidelines`, `mcp-builder`, `slack-gif-creator`, `canvas-design`, `algorithmic-art`, `doc-coauthoring`, `claude-api` |
| `context7` | `claude-plugins-official` | Up-to-date library docs MCP (Upstash, Community Managed) |
| `codex` | `openai-codex` | OpenAI Codex CLI integration: `/codex:setup`, `/codex:rescue`, plus internal helpers |

## License

Personal config — feel free to copy and adapt.
