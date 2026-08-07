---
name: sync-device
description: Pull the latest my-ai-agents snapshot onto this device and apply everything that follows from it — run bootstrap-claude.sh, report which commits landed and what config they changed, verify the per-device setup the snapshot cannot carry (MCP scope, connectors, plugins), then summarise what was actually changed. Use when the user says "sync this device", "sync my-ai-agents", "pull my agents config", "update my claude setup on this machine", "I'm setting up another device", or asks to pull and apply the config repo. Scoped to the my-ai-agents config repo only — this is not a general-purpose git pull.
disable-model-invocation: true
allowed-tools: Read Bash(git status:*) Bash(git log:*) Bash(git diff:*) Bash(git fetch:*) Bash(git pull:*) Bash(git rev-list:*) Bash(git remote:*) Bash(bash Claude/scripts/bootstrap-claude.sh) Bash(bash -n:*) Bash(diff:*) Bash(jq:*) Bash(ls:*) Bash(sed:*) Bash(claude mcp list) Bash(npm ls:*) Bash(command -v:*)
---

# Sync Device

Bring this machine in line with the latest `my-ai-agents` snapshot: pull, install, verify, report.

The repo is a snapshot of `~/.claude/`, not an application. Pulling changes **files in the repo**; it does not change this device until `bootstrap-claude.sh` runs. Those two steps must happen in the same session — see the trap below.

## NEVER

- **Never stop after `git pull`.** A pull that isn't followed by bootstrap is worse than no pull at all (see The trap).
- **Never hand-copy `settings.json`**, and never `cp` the snapshot into `~/.claude/`. The snapshot stores a literal `$HOME` token that only `bootstrap-claude.sh` expands. The hook commands single-quote their paths, so the shell will *not* expand it at runtime — a raw copy leaves every externally-managed hook pointing at a nonexistent path, and because those hooks self-guard with `-f`/`-r`/`-x` tests they fail **silently**.
- **Never edit whitelisted files under `Claude/` in the repo** to fix a drift you spot. The end-of-session sweep copies the live `~/.claude/` version on top and your edit vanishes. Edit under `~/.claude/` and let the hook mirror it in. (Root docs and `Cursor/` are ordinary repo files — edit those in place.)
- **Never resolve a diverged branch by reflex.** Both machines auto-commit, so divergence is normal and expected here. Inspect before merging or rebasing.
- **Never silently apply a config removal.** If the pull removes a plugin/MCP/hook this device is actively using, surface it and let the user decide.

## The trap — why order matters

Two hooks run the snapshot loop: `PostToolUse` on `Edit|Write` mirrors edited live files into the repo, and `Stop` (async) re-sweeps the whitelist, stages `Claude/`, and auto-commits.

So if you pull new scripts and *don't* bootstrap, the `Stop` sweep at session end copies this device's **old** `~/.claude/` files back over the freshly-pulled snapshot and auto-commits the result — silently reverting the pull, and starting a commit ping-pong with the other machine.

**Pull and bootstrap in the same session. Always.**

## Workflow

1. **Locate the repo.** Default `~/Repos/my-ai-agents`; check `~/.claude/.sync-config` for a `SNAPSHOT_REPO` override. Confirm `git remote -v` points at the config repo before touching anything.

2. **Check state before pulling.** `git status` and `git rev-list --left-right --count @{u}...HEAD`.
   - Dirty tree or staged changes → report and stop. Staged content also disables the auto-commit hook, which is worth telling the user.
   - Local commits ahead → these are this device's auto-commits. Say how many; they will be pushed later, not discarded.
   - Diverged (both sides non-zero) → **stop and show both sides.** Ask before merging or rebasing.

3. **Pull.** `git pull --ff-only`. If it refuses, fall back to step 2's divergence path — do not force.

4. **Read what landed.** `git log --oneline <old>..HEAD` and `git diff <old>..HEAD -- Claude/`. Classify each commit by what it does to *this device*:
   - script/hook behavior changes
   - `settings.json` changes — **especially removals** (a dropped plugin, marketplace, or MCP server)
   - agents / skills / rules content
   - docs only (no device impact)

   Flag removals now, before bootstrap applies them. If the device is actively using what's being removed, ask.

5. **Bootstrap.** `bash Claude/scripts/bootstrap-claude.sh` from the repo root. Idempotent; backs up any existing `settings.json` to `settings.json.bak-<timestamp>`; seeds but never overwrites `settings.local.json`.

6. **Verify the sync.** All of these must pass:
   ```bash
   diff <(sed "s|\$HOME/|$HOME/|g" Claude/settings.json) "$HOME/.claude/settings.json"
   for d in scripts agents skills rules; do diff -rq "Claude/$d" "$HOME/.claude/$d"; done
   grep -n '/Users/' Claude/settings.json || echo "no absolute paths"
   jq -e . Claude/settings.json >/dev/null
   bash -n Claude/scripts/*.sh Claude/statusline.sh
   ```
   Then the **round-trip test**, which is the one that actually proves the device won't ping-pong commits with the other machine:
   ```bash
   printf '{"tool_name":"Edit","tool_input":{"file_path":"'"$HOME"'/.claude/settings.json"}}' \
     | bash "$HOME/.claude/scripts/sync-to-snapshot.sh"
   git status --short   # must be empty
   ```
   A non-empty result means the `$HOME` normalization failed — investigate before ending the session, or the `Stop` sweep will commit a path swap.

7. **Check the per-device gaps.** These live outside `~/.claude/` and the snapshot never carries them, so a freshly-synced device can still be wrong. Check each; fix what is safely fixable, report the rest.

8. **Summarise** (see Output).

## Per-device gaps — check every sync

| Gap | Check | Fix |
| --- | --- | --- |
| **Playwright MCP scope** | `jq -r '.mcpServers \| keys[]' ~/.claude.json` — must list `playwright` | `claude mcp add -s user playwright -- "$(command -v node)" "$(npm root -g)/@playwright/mcp/cli.js"` |
| **MCP at project scope** | `jq -r '.projects \| to_entries[] \| select(.value.mcpServers)' ~/.claude.json` | `claude mcp add` defaults to **local** scope. A server registered there exists only in that one project — the classic failure. Re-add with `-s user`, then `claude mcp remove` in the offending project. |
| **claude.ai connectors** | `claude mcp list` — all `✓ Connected` | `! Needs authentication` is account-level; the user must reconnect at claude.ai/settings/connectors. Cannot be fixed from the shell. |
| **Plugins** | compare `jq '.enabledPlugins' ~/.claude/settings.json` against `jq '.plugins \| keys' ~/.claude/plugins/installed_plugins.json` | user runs `/plugin` in-session, then `/reload-plugins`. Enabling in `settings.json` only makes a plugin *known* — the payload still needs fetching. |
| **Removed-plugin residue** | `~/.claude/plugins/cache/` and `known_marketplaces.json` | Dropping a plugin from `settings.json` disables it but leaves the cache and marketplace entry. Harmless; mention it, offer `/plugin` cleanup. |
| **`.sync-config`** | needed only if the clone is *not* at `~/Repos/my-ai-agents` | `echo 'SNAPSHOT_REPO="$HOME/path/to/my-ai-agents"' > ~/.claude/.sync-config` |
| **`node` on inherited PATH** | `command -v node` | Empty while `node --version` works interactively = the nvm lazy-load shim. See `Claude/setup.md` §4 → node-on-PATH gotcha. |
| **`jq`** | `command -v jq` | `brew install jq` — hard dependency of the guard, sync, and statusline scripts. |

Agent count is a cheap sanity check: `ls ~/.claude/agents/` should show eight definitions.

The full end-to-end checklist is `Claude/setup.md` §5. Sync activity and hook aborts land in `~/.claude/sync-to-snapshot.log`.

## Output

Report in this order. Keep it factual — state what was verified versus what was assumed, and never claim a check you didn't run.

1. **Commits pulled** — table of `<sha> <subject>` with a one-line device impact each. Say plainly which were docs-only.
2. **Applied to this device** — what bootstrap installed; name the `settings.json` backup file.
3. **Verified** — which checks passed, naming the round-trip test explicitly.
4. **Gaps found** — split into *fixed* (say exactly what command ran) and *needs the user* (connector auth, `/plugin`, anything ambiguous). If nothing was wrong, say so.
5. **Decisions pending** — anything surfaced at step 4 that the user hasn't answered.

If the repo was already up to date, say that in one line, but still run steps 6–7 — the device can drift from an unchanged snapshot.
