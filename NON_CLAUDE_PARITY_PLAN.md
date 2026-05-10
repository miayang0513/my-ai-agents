# Non-Claude Parity Plan

This document describes how to ship a version of this repository for users who do not have Claude, while preserving the same functional behavior as closely as possible.

## Goal

Provide an AI-agent environment that keeps the same core capabilities as the current Claude-based setup:

- global instruction policy
- path-scoped rules
- role-based subagents
- reusable skills
- lifecycle hooks (safety, sync, auto-commit, logging)
- MCP-style tool integrations
- status line and session ergonomics

## Current Capability Inventory

The existing implementation lives under `Claude/` and includes:

- policy + memory:
  - `Claude/CLAUDE.md`
  - `Claude/rules/*.md`
- roles:
  - `Claude/agents/*.md`
- skills:
  - `Claude/skills/*/SKILL.md`
- runtime wiring:
  - `Claude/settings.json`
  - `Claude/settings.local.json`
- automation scripts:
  - `Claude/scripts/guard-bash.sh`
  - `Claude/scripts/sync-to-snapshot.sh`
  - `Claude/scripts/auto-commit-snapshot.sh`
  - `Claude/scripts/log-instructions-loaded.sh`
- UI:
  - `Claude/statusline.sh`

## Main Lock-In Points

1. Claude CLI lifecycle and hook schema (`PreToolUse`, `PostToolUse`, `Stop`, `InstructionsLoaded`).
2. `~/.claude/*` filesystem conventions.
3. Claude command usage in scripts (`claude --print` in auto-commit flow).
4. Claude-specific MCP naming patterns in agent tool lists (`mcp__claude_ai_*`).
5. Claude plugin marketplace + slash-command workflows.

## Target Architecture (Provider-Agnostic)

Create a provider-agnostic distribution with a thin compatibility layer:

- `platform/` (new): normalized runtime contracts
  - `events/` (tool/session lifecycle event shapes)
  - `providers/` (Claude, Cursor, Codex, generic API adapters)
  - `mcp/` (tool namespace mapping)
- `shared/` (new): reusable assets independent of provider
  - `rules/`, `skills/`, `agents/` source-of-truth
- `dist/<provider>/` (new): generated provider-specific output
  - `dist/claude/` mirrors current behavior
  - `dist/cursor/` and/or `dist/generic/` for non-Claude users

## Parity Matrix

| Capability | Current Source | Parity Strategy (Non-Claude) | Parity Level |
| --- | --- | --- | --- |
| Global instruction policy | `Claude/CLAUDE.md` | Compile into target provider global/system prompt format | Exact |
| Path-scoped rules | `Claude/rules/*.md` | Convert glob metadata into target rule mechanism; fallback to prompt injection by path | Near-exact |
| Role subagents | `Claude/agents/*.md` | Convert role definitions to target agent schema and tool permissions | Near-exact |
| Skills | `Claude/skills/*` | Keep markdown skill content; adapt trigger metadata to host format | Near-exact |
| Bash safety guard | `scripts/guard-bash.sh` | Keep script; wire via provider hook or wrapper shell | Exact |
| Snapshot sync | `scripts/sync-to-snapshot.sh` | Keep logic; replace Claude event input with normalized JSON adapter | Exact |
| Auto commit message | `scripts/auto-commit-snapshot.sh` | Replace direct Claude call with provider command adapter | Exact |
| Instructions-loaded logging | `scripts/log-instructions-loaded.sh` | Emit equivalent events from runtime wrapper if provider lacks this event | Near-exact |
| Status line | `statusline.sh` | Map provider session payload to expected fields, keep script interface stable | Near-exact |
| MCP connectors | agent tool lists + setup | Introduce name mapping (`logical_tool -> provider_tool`) | Near-exact |

## Implementation Plan

### Phase 1: Decouple scripts from Claude hardcoding

1. Introduce a single config file for runtime paths and provider commands.
2. Remove hardcoded `.claude` assumptions where possible.
3. Add an adapter command contract for AI-generated commit messages:
   - input: prompt on stdin
   - output: one plain-text commit message line on stdout

Success check:

- scripts run without requiring `claude` binary when alternative adapter is configured.

### Phase 2: Normalize event payloads

1. Define a minimal event schema used by existing hooks:
   - `event_name`
   - `tool_name`
   - `tool_input.command`
   - `tool_input.file_path`
2. Add provider-specific translators that convert host events into this schema.

Success check:

- `guard-bash.sh` and `sync-to-snapshot.sh` behave identically under non-Claude runtime.

### Phase 3: Rules/agents/skills transpilation

1. Keep source-of-truth content in provider-neutral markdown with metadata.
2. Generate provider-specific files from one source.
3. Add validation scripts to ensure no missing role/skill/rule in each target.

Success check:

- same role names, same skill set, same rule topics available across providers.

### Phase 4: MCP tool mapping

1. Replace hardcoded provider tool IDs in role files with logical names.
2. Maintain per-provider mapping tables.
3. Validate required tool coverage during setup.

Success check:

- each role can call equivalent tools even if provider namespaces differ.

### Phase 5: Distribution and setup UX

1. Provide setup docs by target:
   - `setup-claude.md`
   - `setup-non-claude.md` (or provider-specific docs)
2. Add a preflight script to verify required binaries/configuration.

Success check:

- a new user can bootstrap without Claude and still get equivalent workflows.

## Concrete Backlog

Priority order:

1. Add provider adapter contract for commit-message generation.
2. Externalize path/provider config into one file.
3. Add event normalizer wrapper used by all hooks.
4. Introduce logical MCP tool aliases in role definitions.
5. Split docs into provider-specific setup guides.
6. Add parity test checklist that validates every capability.

## Risks

- Exact parity may be impossible for features where host runtimes do not expose matching lifecycle events.
- Connector ecosystems differ by provider; some integrations may require custom MCP servers.
- Agent behavior can vary by model even with identical prompts.

## Acceptance Criteria

A non-Claude user is considered fully supported when they can:

1. install and start the environment without Claude CLI,
2. run role-based delegation with the same role set,
3. trigger equivalent skills and rule behavior,
4. get guard/sync/auto-commit hooks working end-to-end,
5. use mapped MCP/integration tools for the same workflows.
