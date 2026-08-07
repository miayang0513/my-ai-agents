# Claude Code Setup — From 0

A complete guide to setting up Claude Code, from installation to advanced configuration.

For a faster overview (what's included, hooks, MCP, plugins), see [`README.md`](./README.md).
All setup procedures and verification steps are intentionally centralized in this file.

---

## 1. Install

### Prerequisites

- macOS with a terminal (zsh, bash, fish all fine)
- **`jq`** — required by `statusline.sh` and `scripts/guard-bash.sh`
- **`node`** — required by the local MCP server (Playwright, run via a globally-installed CLI — see §3) and by `typescript-lsp`. Any working install on `PATH` (Homebrew, nvm, asdf) is fine. If MCPs fail with `node: command not found`, see §4 → **node-on-PATH gotcha** for the fix.

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
- `./settings.local.json` → `~/.claude/settings.local.json` — machine-local permission allowlist (gitignored, so absent on a fresh clone; the bootstrap script creates an empty one)
- [`./statusline.sh`](./statusline.sh) → `~/.claude/statusline.sh` — custom status line (wired up in `settings.json`)
- [`./scripts/guard-bash.sh`](./scripts/guard-bash.sh) → `~/.claude/scripts/guard-bash.sh` — destructive-Bash-command blocker (wired up under `hooks.PreToolUse` in `settings.json`)
- [`./scripts/log-instructions-loaded.sh`](./scripts/log-instructions-loaded.sh) → `~/.claude/scripts/log-instructions-loaded.sh` — appends each `InstructionsLoaded` event as JSONL to `~/.claude/logs/instructions-loaded.jsonl`. Useful for debugging which path-scoped rules fired on which file reads.
- [`./agents/`](./agents/) → `~/.claude/agents/` — role-based subagents
- [`./skills/`](./skills/) → `~/.claude/skills/` — hand-written skills loaded on demand
- [`./rules/`](./rules/) → `~/.claude/rules/` — path-scoped rules

Run the bootstrap script from the repo root:

```bash
bash Claude/scripts/bootstrap-claude.sh
```

It installs everything above, backs up any existing `settings.json`, and is idempotent — re-run it after each `git pull` to update the device.

> **Do not hand-copy `settings.json`.** The snapshot stores a literal `$HOME` token in that file rather than an absolute path (see [Per-device config](#per-device-config) below). The hook commands quote their paths with single quotes, so the shell will *not* expand the token at runtime — a raw `cp` leaves every externally-managed hook pointing at a path that doesn't exist. Because those hooks guard themselves with `-f`/`-r`/`-x` tests, they fail silently rather than erroring. `bootstrap-claude.sh` expands the token for you.

### Per-device config

Two things are intentionally device-local and must never be shared between machines:

| File | Why | Mechanism |
| --- | --- | --- |
| `~/.claude/settings.local.json` | Permission allowlist each machine accumulates on its own | Gitignored; excluded from the sync whitelist. `bootstrap-claude.sh` seeds it once, then never overwrites it. |
| Absolute paths inside `settings.json` | Externally-managed hooks (orca) bake in `/Users/<name>/…`, which differs per machine | `sync-to-snapshot.sh` rewrites `/Users/<name>/` to `$HOME/` on the way into the snapshot; `bootstrap-claude.sh` expands it on the way out. |

Without the second rule, two machines with different usernames each see a diff on every session and auto-commit a path swap, ping-ponging commits indefinitely.

After copying `settings.json`, the listed marketplaces and `enabledPlugins` are *known* to Claude Code but the plugin payloads still need to be fetched. Open a session, run `/plugin`, and install each plugin shown as enabled. See §4 → **Plugins & Skills** for the full list.

`guard-bash.sh` blocks `rm -rf`, `git push --force`, `git reset --hard`, `npm publish`, and friends before they execute (regardless of which agent or session ran them). Edit the `PATTERNS` array in the script to adjust the denylist.

### Per-device steps (NOT covered by the snapshot)

Three things live outside `~/.claude/` and must be redone on every new machine:

**1. Claude.ai-managed MCP connectors** — tied to your account, not local files. After logging in, connect each at [claude.ai/settings/connectors](https://claude.ai/settings/connectors):

- [ ] Notion
- [ ] Gmail
- [ ] Google Calendar
- [ ] Google Drive
- [ ] Figma

**2. Local MCP server** — Playwright. Stored in `~/.claude.json` (user-scope MCP config), separate from `~/.claude/settings.json`, so it doesn't come along with the snapshot. Install the CLI globally and point Claude at it directly — **not** `npx -y`, which re-resolves the package from the npm registry on *every* launch and adds ~15s to `claude` startup:

```bash
npm i -g @playwright/mcp                      # install once, under your active node

NODE="$(command -v node)"
claude mcp add playwright -- "$NODE" "$(npm root -g)/@playwright/mcp/cli.js"
```

> This resolves to an absolute path under your *current* node. With nvm the path is version-specific — after `nvm install` / switching the default, re-run `npm i -g …` and re-add (or hand-edit the path in `~/.claude.json`).

**3. Snapshot path override** — only needed if your clone of `my-ai-agents` isn't at `~/Repos/my-ai-agents`. The auto-sync hooks (`scripts/sync-to-snapshot.sh`, `scripts/auto-commit-snapshot.sh`) default to that path. To point them somewhere else, create `~/.claude/.sync-config`:

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

**Required on a new device** — the local MCP below is stored in `~/.claude.json`, not `~/.claude/settings.json`, so the §3 snapshot copy does NOT bring it over. Install + add per-device (see §3 → step 2 for why we avoid `npx -y`):

```bash
npm i -g @playwright/mcp
NODE="$(command -v node)"

# Browser automation — drives a real Chromium for navigating, clicking, scraping
claude mcp add playwright -- "$NODE" "$(npm root -g)/@playwright/mcp/cli.js"
```

After adding, re-run `claude mcp list` to confirm it shows `✓ Connected`.

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

Plugin marketplaces are git-backed sources of plugins. Two are configured (see `extraKnownMarketplaces` in `settings.json`):

| Marketplace | Source | Add command |
| --- | --- | --- |
| `claude-plugins-official` | bundled by default | (already present) |
| `anthropic-agent-skills` | `anthropics/skills` | `/plugin marketplace add anthropics/skills` |

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

#### node-on-PATH gotcha

Anything Claude Code spawns as a subprocess — the local MCP servers (§3 step 2), `typescript-lsp`, or any plugin hook that shells out to `node` — resolves binaries from the `PATH` the harness inherited, **not** from your interactive shell.

First check whether node exists at all:

```bash
command -v node || echo "no node installed"
```

If it prints nothing but `node --version` works in your terminal, the binary exists and only `PATH` is the problem. That is most common on macOS with nvm, whose *lazy-load* shim (`_load_nvm`) only fires inside an interactive zsh — launch Claude Code from cmux, a Ghostty plugin, or an IDE that doesn't source `.zshrc` and `node` is absent for spawned subprocesses.

Two fixes — pick one:

- **Symlink nvm's node onto the system PATH** (no second toolchain):

  ```bash
  ln -sf "$(command -v node)" /opt/homebrew/bin/node
  ```

  `/opt/homebrew/bin` is on the inherited `PATH` even for GUI-launched apps. Caveat: the symlink points at one *specific* nvm version — repoint it after switching node versions.

- **Install a system Node** (no version coupling, but a second node alongside nvm):

  ```bash
  brew install node      # node lives in /opt/homebrew/bin/, always on PATH
  ```

Verify with `claude mcp list` — Playwright should report `✓ Connected`.

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
6. `claude mcp list` → all five Claude.ai-managed servers (Notion, Gmail, Calendar, Drive, Figma) **and** the local one (Playwright) show `✓ Connected`
7. `claude agents` → all custom subagents listed (`frontend-engineer`, `backend-engineer`, `devops-engineer`, `product-manager`, `uiux-designer`, `qa-engineer`, `security-reviewer`)
8. Trigger a destructive Bash command (e.g. ask Claude to run `rm -rf /tmp/nope`) → guard-bash hook blocks it with the "Blocked by …" message

If any step fails, check `~/.claude/logs/` for harness errors.

---

## References

- Docs: https://docs.claude.com/en/docs/claude-code
- Issues / feedback: https://github.com/anthropics/claude-code/issues
- API console (for API-key auth): https://console.anthropic.com
