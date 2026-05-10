# Claude Code Setup — From 0

A complete guide to setting up Claude Code, from installation to advanced configuration.

For a faster overview (what's included, hooks, MCP, plugins), see [`README.md`](./README.md).
All setup procedures and verification steps are intentionally centralized in this file.

---

## 1. Install

### Prerequisites

- macOS with a terminal (zsh, bash, fish all fine)
- **`jq`** — required by `statusline.sh` and `scripts/guard-bash.sh`
- **`node`** — required by the Codex plugin hooks and `npx`-based MCPs (Playwright, Firecrawl). Any working install on `PATH` (Homebrew, nvm, asdf) is fine. If hooks/MCPs fail with `node: command not found`, see §4 → **Codex plugin — install + nvm gotcha** for the fix.

```bash
brew install jq
```

### Install the CLI

The official recommended install is a one-line curl script — no Node or npm required:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

This drops the `claude` binary into `~/.local/bin` (or a similar user-local path) and prints any `PATH` instructions you may need to follow.

Verify:

```bash
claude --version
```

If `claude` is not found, add the install location to `PATH`:

```bash
# zsh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

Update later with:

```bash
claude update
```

---

## 2. Authenticate

Run `claude` in any directory. On first launch you'll be prompted to log in. Two options:

| Method | When to use |
| --- | --- |
| **Claude.ai subscription** (Pro / Max / Team) | You already pay for Claude.ai and want unified billing |
| **Anthropic API key** | You want pay-as-you-go usage via console.anthropic.com |

Switch later with `/login` inside the CLI, or `claude /login`.

To check current account: `/status`.

---

## 3. Configuration

Drop these files into `~/.claude/` to bootstrap your global config:

- [`./CLAUDE.md`](./CLAUDE.md) → `~/.claude/CLAUDE.md` — your global preferences
- [`./settings.json`](./settings.json) → `~/.claude/settings.json` — main config (theme, status line, enabled plugins, known marketplaces, PreToolUse Bash guard)
- [`./settings.local.json`](./settings.local.json) → `~/.claude/settings.local.json` — machine-local permission allowlist
- [`./statusline.sh`](./statusline.sh) → `~/.claude/statusline.sh` — custom status line (wired up in `settings.json`)
- [`./scripts/guard-bash.sh`](./scripts/guard-bash.sh) → `~/.claude/scripts/guard-bash.sh` — destructive-Bash-command blocker (wired up under `hooks.PreToolUse` in `settings.json`)
- [`./scripts/log-instructions-loaded.sh`](./scripts/log-instructions-loaded.sh) → `~/.claude/scripts/log-instructions-loaded.sh` — appends each `InstructionsLoaded` event as JSONL to `~/.claude/logs/instructions-loaded.jsonl`. Useful for debugging which path-scoped rules fired on which file reads.
- [`./agents/`](./agents/) → `~/.claude/agents/` — role-based subagents
- [`./skills/`](./skills/) → `~/.claude/skills/` — hand-written skills loaded on demand
- [`./rules/`](./rules/) → `~/.claude/rules/` — path-scoped rules

Run from inside the `Claude/` directory of this repo:

```bash
cd Claude/    # the snapshot directory in this repo

cp CLAUDE.md             ~/.claude/CLAUDE.md
cp settings.json         ~/.claude/settings.json
cp settings.local.json   ~/.claude/settings.local.json
cp statusline.sh         ~/.claude/statusline.sh
mkdir -p ~/.claude/scripts && cp scripts/*.sh         ~/.claude/scripts/
mkdir -p ~/.claude/agents  && cp agents/*.md          ~/.claude/agents/
mkdir -p ~/.claude/skills  && cp -R skills/*          ~/.claude/skills/
mkdir -p ~/.claude/rules   && cp rules/*.md           ~/.claude/rules/
chmod +x ~/.claude/statusline.sh ~/.claude/scripts/*.sh
```

After copying `settings.json`, the listed marketplaces and `enabledPlugins` are *known* to Claude Code but the plugin payloads still need to be fetched. Open a session, run `/plugin`, and install each plugin shown as enabled. See §4 → **Plugins & Skills** for the full list.

`guard-bash.sh` blocks `rm -rf`, `git push --force`, `git reset --hard`, `npm publish`, and friends before they execute (regardless of which agent or session ran them). Edit the `PATTERNS` array in the script to adjust the denylist.

### Per-device steps (NOT covered by the snapshot)

Four things live outside `~/.claude/` and must be redone on every new machine:

**1. Claude.ai-managed MCP connectors** — tied to your account, not local files. After logging in, connect each at [claude.ai/settings/connectors](https://claude.ai/settings/connectors):

- [ ] Notion
- [ ] Gmail
- [ ] Google Calendar
- [ ] Google Drive
- [ ] Figma

**2. Local MCP servers** — Playwright and Firecrawl. These are stored in `~/.claude.json` (user-scope MCP config), separate from `~/.claude/settings.json`, so they don't come along with the snapshot. Re-add them:

```bash
claude mcp add playwright -- npx -y @playwright/mcp
claude mcp add firecrawl -e FIRECRAWL_API_KEY=<your-key> -- npx -y firecrawl-mcp
```

**3. `FIRECRAWL_API_KEY`** — secret, intentionally not in this repo. Pull from your password manager, or generate a new one at [firecrawl.dev/app/api-keys](https://www.firecrawl.dev/app/api-keys) (see §4 → MCP servers for the walkthrough).

**4. Snapshot path override** — only needed if your clone of `my-ai-agents` isn't at `~/Repos/my-ai-agents`. The auto-sync hooks (`scripts/sync-to-snapshot.sh`, `scripts/auto-commit-snapshot.sh`) default to that path. To point them somewhere else, create `~/.claude/.sync-config`:

```bash
echo 'SNAPSHOT_REPO="$HOME/code/my-ai-agents"' > ~/.claude/.sync-config
```

`.sync-config` is per-device (deliberately not in the snapshot's whitelist) so each machine can have its own path. Username variation is handled automatically — both scripts use `$HOME` rather than a hardcoded `/Users/<name>/`.

---

## 4. Advanced

### MCP servers

MCP (Model Context Protocol) servers extend Claude with external tools (Gmail, Notion, Drive, custom APIs).

**Step 1 — check what's already connected:**

```bash
claude mcp list
```

The Claude.ai-managed MCP servers I rely on:

```
claude.ai Notion:           https://mcp.notion.com/mcp                    - ✓ Connected
claude.ai Gmail:            https://gmailmcp.googleapis.com/mcp/v1        - ✓ Connected
claude.ai Google Calendar:  https://calendarmcp.googleapis.com/mcp/v1     - ✓ Connected
claude.ai Google Drive:     https://drivemcp.googleapis.com/mcp/v1        - ✓ Connected
claude.ai Figma:            https://mcp.figma.com/mcp                     - ✓ Connected
```

If you signed in with a Claude.ai subscription, these four come pre-wired — no manual setup needed. If any are missing, connect them at [claude.ai/settings/connectors](https://claude.ai/settings/connectors).

**Step 2 — add your own:**

```bash
claude mcp add <name> <command> [args...]   # add
claude mcp remove <name>                    # remove
```

Servers can also be declared in `settings.json` under `mcpServers`. Once added, their tools appear in-session as `mcp__<server>__<tool>`.

**Required on a new device** — the local MCPs below are stored in `~/.claude.json`, not `~/.claude/settings.json`, so the §3 snapshot copy does NOT bring them over. Re-add them per-device:

```bash
# Browser automation — drives a real Chromium for navigating, clicking, scraping
claude mcp add playwright -- npx -y @playwright/mcp

# Web scraping / crawling — needs FIRECRAWL_API_KEY (see below)
claude mcp add firecrawl -e FIRECRAWL_API_KEY=<your-key> -- npx -y firecrawl-mcp
```

**Getting `FIRECRAWL_API_KEY`** (assuming you already have a Firecrawl account):

1. Sign in at [firecrawl.dev](https://www.firecrawl.dev/).
2. Go to the dashboard → **API Keys** (left sidebar, or [firecrawl.dev/app/api-keys](https://www.firecrawl.dev/app/api-keys)).
3. Click **Create API Key**, copy the value (starts with `fc-`).
4. Pass it via `-e FIRECRAWL_API_KEY=...` when running `claude mcp add` (above), or export it in your shell before launching `claude`.

After adding, re-run `claude mcp list` to confirm both show `✓ Connected`. If `firecrawl` shows `✗ Failed to connect`, double-check the key is set.

### Hooks

Use hooks to automate guardrails and sync behavior. This repo already wires hooks in `settings.json`.

Configured in `settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [{ "type": "command", "command": "npm run lint --silent" }]
      }
    ]
  }
}
```

Use `/update-config` to add/troubleshoot hooks. For hook overview, see [`README.md`](./README.md#hooks-at-a-glance).

### Plugins & Skills

Use `/plugin` to install/update plugins and `/reload-plugins` to apply changes in-session.

#### Marketplaces

Plugin marketplaces are git-backed sources of plugins. Three configured on this machine (see `extraKnownMarketplaces` in `settings.json`):

| Marketplace | Source | Add command |
| --- | --- | --- |
| `claude-plugins-official` | bundled by default | (already present) |
| `anthropic-agent-skills` | `anthropics/skills` | `/plugin marketplace add anthropics/skills` |
| `openai-codex` | `openai/codex-plugin-cc` | `/plugin marketplace add openai/codex-plugin-cc` |

#### Plugin commands (run inside a Claude session)

```
/plugin marketplace add <gh-org>/<repo>     # add a marketplace
/plugin                                     # interactive install/uninstall UI
/reload-plugins                             # apply changes to current session
```

#### Plugins installed

Installed plugin catalog lives in [`README.md` -> Plugins used](./README.md#plugins-used).

Setup reminder:

- after copying `settings.json`, run `/plugin` to install enabled plugins
- run `/reload-plugins` after install/update in the current session

#### Codex plugin — install + nvm gotcha

The Codex plugin needs a working `node` on `PATH` because its three lifecycle hooks (`SessionStart`, `SessionEnd`, `Stop`) shell out to `node /path/to/script.mjs`. If `node` isn't found you'll see:

```
⏺ Ran 3 stop hooks
  ⎿  Stop hook error: Failed with non-blocking status code: /bin/sh: node: command not found
```

**Install:**

```text
/plugin marketplace add openai/codex-plugin-cc   # add the marketplace
/plugin                                          # → install "codex"
/reload-plugins                                  # apply
```

**Make node reachable** — most relevant on macOS where Node is commonly nvm-managed with a *lazy-load* shim (`_load_nvm`). That shim only fires inside an interactive zsh, so when Claude Code is launched from a wrapper like cmux/Ghostty plugins/an IDE that doesn't source `.zshrc`, neither `node` nor `npx` are on `PATH` for spawned subprocesses (this also breaks `npx`-based MCPs like Playwright and Firecrawl, not just Codex).

The robust fix is to install a system Node so it lives on the inherited `PATH`:

```bash
brew install node      # puts node + npx in /opt/homebrew/bin/, always on PATH
```

After that, `claude mcp list` should show Playwright and Firecrawl as `✓ Connected`, and the Codex hooks stop erroring.

#### Built-in skills (no install needed)

`/init`, `/review`, `/security-review`, `/simplify`, `/loop`, `/schedule`, `/update-config`, `/keybindings-help`, `/fewer-permission-prompts`, `/claude-api`.

#### Local skills

Hand-written skills live next to your config:

- Global: `~/.claude/skills/<name>/SKILL.md`
- Project: `<repo>/.claude/skills/<name>/SKILL.md`

Each skill is a folder with a `SKILL.md` describing what it does and when to trigger. Create one with `/skill-creator`.

---

## 5. Sanity Check

After setup, confirm everything works end-to-end:

1. `claude --version` → prints version
2. `claude` in a repo → starts a session
3. `/status` → shows logged-in account and model
4. Ask Claude to run `!git status` → executes shell command
5. Edit a file via Claude → `git diff` shows expected change
6. `claude mcp list` → all five Claude.ai-managed servers (Notion, Gmail, Calendar, Drive, Figma) **and** the two local ones (Playwright, Firecrawl) show `✓ Connected`
7. `claude agents` → all custom subagents listed (`frontend-engineer`, `backend-engineer`, `devops-engineer`, `product-manager`, `uiux-designer`, `qa-engineer`, `security-reviewer`)
8. Trigger a destructive Bash command (e.g. ask Claude to run `rm -rf /tmp/nope`) → guard-bash hook blocks it with the "Blocked by …" message

If any step fails, check `~/.claude/logs/` for harness errors.

---

## References

- Docs: https://docs.claude.com/en/docs/claude-code
- Issues / feedback: https://github.com/anthropics/claude-code/issues
- API console (for API-key auth): https://console.anthropic.com
