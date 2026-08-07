# Cursor Setup — From 0 (Parity Edition)

A complete guide to set up the Cursor edition of this repo, from bootstrap to verification.

For a quick inventory (what files are included), see [`README.md`](./README.md).
All setup and validation steps are intentionally centralized here.

---

## 1. Install and prerequisites

### Prerequisites

- macOS with a terminal (`zsh` assumed below)
- `git` on `PATH`
- `bash` on `PATH`
- Cursor desktop app installed and signed in

### Install Cursor CLI (`cursor-agent`)

Use the official one-line installer:

```bash
curl https://cursor.com/install -fsS | bash
```

This installs Cursor CLI commands (including `agent`) into your user-local bin path.
For this repo, we use `cursor-agent` as the adapter command in scripts.

Alternative (UI path): in Cursor Command Palette, run the shell-command install action.

In Cursor:

1. Open Command Palette.
2. Run the install-shell-command action (search for `cursor-agent` or `install command`).
3. Accept any OS permission prompt.
4. Open a new terminal.

Verify:

```bash
agent --version
cursor-agent --help
```

Expected result: `agent --version` prints a version and `cursor-agent --help` prints help text.

If command is still not found:

```bash
# zsh
echo "$PATH"
source ~/.zshrc
cursor-agent --help
```

If it still fails, restart Cursor and terminal, then run the shell-command install action again.

---

## 2. Bootstrap this repo into a target project

Run from this repo:

```bash
cd /path/to/my-ai-agents
bash Cursor/scripts/bootstrap-cursor-project.sh /path/to/your-project
```

This provisions, in your target project:

- `.cursor/rules/` from `Cursor/rules/`
- `.cursor/agents/` from `Cursor/agents/`
- `.cursor/skills/` from `Cursor/skills/`
- `.cursor/scripts/gen-commit-message.sh`
- `.git/hooks/pre-commit` with portable guard logic

The bootstrap is idempotent for normal re-runs; re-running is the intended update path after you change this repo.

---

## 3. Configure Cursor CLI for commit message generation (optional)

Set one environment variable so `gen-commit-message.sh` knows how to call your AI CLI adapter.
For Cursor-native usage:

```bash
export AI_COMMIT_CMD='cursor-agent prompt --model gpt-5.5-medium --quiet'
```

Persist it (zsh):

```bash
echo "export AI_COMMIT_CMD='cursor-agent prompt --model gpt-5.5-medium --quiet'" >> ~/.zshrc
source ~/.zshrc
```

Run a quick runtime/auth sanity check:

```bash
cursor-agent prompt --model gpt-5.5-medium --quiet "reply with: ok"
```

Then generate a commit message from staged changes:

```bash
bash .cursor/scripts/gen-commit-message.sh
```

Contract expected by the script:

- it sends prompt text to `AI_COMMIT_CMD` via stdin
- command returns one plain-text line on stdout
- output must satisfy the Conventional Commit validator in the script

If `AI_COMMIT_CMD` is missing, the script prints setup guidance and exits cleanly.

---

## 4. MCP setup and parity mapping

Cursor supports MCP, but server IDs/tool names often differ from Claude naming.

### Practical setup order

1. Bootstrap this repo into your project (Section 2).
2. Enable/install MCP servers in Cursor for tools your agents need:
   - `context7`
   - `figma`
   - `playwright`
   - optional productivity servers (`notion`, `google_calendar`, `google_drive`)
3. Open `.cursor/agents/*.md` in your target project.
4. In each `tools:` field, map names to your local MCP IDs.
5. Run verification prompts (Section 6).

### Tool-name remap example

If your installed server ID is `plugin-context7-context7`, update tool namespace usage from:

- `mcp__context7__...`

to:

- `mcp__plugin-context7-context7__...`

### Capability mapping (Claude -> Cursor)

- `Cursor/rules/*.md` -> `.cursor/rules/*.md` (direct copy)
- `Cursor/agents/*.md` -> `.cursor/agents/*.md` (direct copy)
- `Cursor/skills/*` -> `.cursor/skills/*` (direct copy)
- Claude hook-style Bash guard -> git-hook guard wrapper
- Claude auto-commit helper -> `.cursor/scripts/gen-commit-message.sh` adapter flow

---

## 5. Known runtime differences

- Cursor does not expose the same lifecycle hooks as Claude (`InstructionsLoaded`, `PostToolUse`), so parity uses git hooks and scripts where needed.
- Claude.ai-managed connector namespaces (for example `mcp__claude_ai_*`) are not portable 1:1 to Cursor.
- Plugin marketplace behavior differs; prefer local skills plus Cursor-native integrations for reproducibility.
- Role quality can vary by selected model and currently enabled tools.

---

## 6. Sanity check (end-to-end)

After setup, confirm this checklist in your target project:

1. `cursor-agent --help` works in terminal.
2. `bash .cursor/scripts/gen-commit-message.sh` prints "No staged changes" when nothing is staged.
3. Stage a small file change, run the script again, and get one valid Conventional Commit line.
4. Open a Cursor chat and confirm agent files are present under `.cursor/agents/`.
5. Ask for a docs lookup via Context7 and confirm MCP tool invocation succeeds.
6. Ask for a simple Playwright action and confirm tool call succeeds.
7. Trigger a clearly disallowed shell command in a commit flow and confirm the pre-commit guard blocks it.

If checks fail:

- verify bootstrap target path
- verify `.git/hooks/pre-commit` exists and is executable
- verify MCP server is installed, enabled, and authenticated
- verify tool namespace matches `mcp__<your-server-id>__<tool>`
- verify `AI_COMMIT_CMD` in current shell (`echo "$AI_COMMIT_CMD"`)

---

## 7. Troubleshooting quick reference

### `cursor-agent: command not found`

- Re-run shell-command install from Cursor Command Palette.
- Open a new terminal.
- Reload shell config (`source ~/.zshrc`).
- Re-check with `cursor-agent --help`.

### `AI_COMMIT_CMD is not set`

- Export `AI_COMMIT_CMD` in current shell.
- Add it to `~/.zshrc` if you want persistence.
- Re-open shell and retry.

### Generated message fails validation

- Ensure CLI output is one line of plain text.
- Remove wrappers that add markdown/code fences.
- Keep output in Conventional Commit format expected by script.

### MCP tool not found

- Confirm server is installed/enabled in Cursor.
- Confirm agent `tools:` entries use your local server ID namespace.
- Retry after authentication if server requires sign-in.
