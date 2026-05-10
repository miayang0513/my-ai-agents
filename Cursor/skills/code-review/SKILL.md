---
name: code-review
description: Review the user's pending/uncommitted work — staged + unstaged changes only, never committed history or branch-wide diffs. Trigger on "review my changes", "code review", "review this diff", "review what I'm working on", "review my WIP", or when the user points at a specific dirty file/hunk. Runs the repo's lint/format check scripts if present, produces a structured report (Summary, Issues with severity/file/line, Action items, verbatim tool output), then applies fixes directly to the codebase while keeping the user's original work staged and all of the skill's edits unstaged so the separation is visible in `git diff`. Use `code-review-branch` instead when the user wants their entire branch reviewed against a base like `develop`/`main`. Supports findings-only mode (no fixes, no git state changed) when invoked by a read-only reviewer.
---

# Code Review (uncommitted scope)

Review only what the user has not yet committed. Stage their work, leave your fixes unstaged, never touch commit history.

## Scope contract

- **In scope:** the working tree — staged + unstaged changes at the moment the skill runs.
- **Out of scope:** committed changes, branch-vs-base diffs, history rewrites. If the user wants those, hand off to `code-review-branch`.
- **Never run:** `git commit`, `git commit --amend`, `git reset`, `git push`, `git rebase`, `git stash drop`.
- **Never stage your own fixes.** Only the user's pre-existing work stays staged; your edits remain unstaged so the user sees a clean before/after in `git diff`.

## Modes

**Default — review and apply fixes.** What an engineer wants when self-polishing. Run all steps. Stage user's work as baseline (step 2), apply fixes as unstaged edits (step 6) — the staged-vs-unstaged separation in `git diff` is the load-bearing pattern.

**Findings-only.** Invoked when the caller says "no fixes" / "report only" / "review without patching", or when the calling agent is `code-reviewer`. Never modify git state, never edit files. Skip step 2 (no `git add`) and skip step 6 (no fixes). In step 3, read uncommitted work via `git diff` and `git diff --cached` directly. The report from step 5 is the deliverable.

## Defaults

- **Package manager:** detect from the lockfile — `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `bun.lockb` / `bun.lock` → bun, else npm. Use that PM for every script run below.
- **Review target:** if the user names a specific file/path (e.g. "review `src/auth.ts`"), scope every `git add` and `git diff --cached` to that path. Otherwise, full working tree.

## Procedure

### 1. Run the repo's check scripts (only ones that exist)

Read `package.json` → `scripts`. Run only what's defined; don't invent commands.

- `scripts.lint` → run it, capture full stdout + stderr.
- `scripts["format:check"]` → run it, capture stdout + stderr.
- `scripts.format` → run **only if** the command body contains `--check`, `--list-different`, or the word `check` (i.e. it's check-only, not a writer). Capture output.

If none of these exist, skip tool output entirely — this becomes a findings-only review. Do not substitute other scripts.

### 2. Lock in the user's work as the staged baseline

*Findings-only mode: skip this step entirely — never stage, never modify git state. Read uncommitted work via `git diff` and `git diff --cached` directly in step 3.*

If the user named specific paths, run `git add -- <paths>`. Otherwise run `git add -A` from the repo root. From this point forward, the staged diff IS the user's work. Do not restage, unstage, or rewrite it.

Deleted files: `git add` will stage the deletion and `git diff --cached` will show it. Review the deletion intent (was it accidental? does anything still import it?), but don't re-add files the user clearly meant to remove.

### 3. Determine review scope

```
git status
git diff --cached            # or: git diff --cached -- <paths>
```

Review **only** the cached diff (scoped to `<paths>` if the user named any). Ignore committed changes and branch-wide diffs even if they look interesting.

*Findings-only mode: there's no staging baseline (step 2 was skipped). Read both `git diff` (truly unstaged) and `git diff --cached` (already-staged) — their union is the review scope. `git diff --cached` alone would miss work the user hasn't staged yet.*

### 4. Apply project rules during review

If `.cursor/rules/*` exists, read the relevant rule files (architecture, naming, TypeScript, imports, framework-specific) and apply them as review criteria. Don't restate the rules in the report — just use them to find issues.

If the diff includes React/Next.js code, also apply Vercel React best practices. If the repo has `docs/VERCEL_REACT_BEST_PRACTICES_AGENTS.md` (or similar), read it; otherwise rely on standard guidance.

### 5. Produce the structured report

Output in this order:

- **Summary** — 2–5 bullets on what changed and why it matters.
- **Issues** — one entry per problem, with:
  - severity (`blocker` / `major` / `minor` / `nit`)
  - file + line range
  - what's wrong
  - concrete suggestion (what to change)
- **Positive notes** *(optional)* — call out genuinely good patterns; skip if there's nothing real to say.
- **Action items** — checklist of what the user should verify / do before committing.
- **Tool output** — verbatim stdout/stderr for every check actually executed. If a single block is enormous, mark it clearly as truncated and keep the warnings/errors intact.

### 6. Apply fixes — keep them unstaged

*Findings-only mode: skip this step entirely. The report from step 5 is the deliverable — never edit files.*

For every Issue you listed and every warning/error from the executed checks, edit the code directly to fix it. Follow project conventions from `.cursor/rules/*` (import aliases, types vs constants layout, etc.).

**Do not `git add` your edits.** When you finish, the state must be:

- Staged: only the user's original work (untouched since step 2).
- Unstaged: your fixes, visible in `git diff`.

A final `git status` should make this separation obvious.

## When NOT to use this skill

- User asks to review the whole branch / compare against `main` or `develop` → use `code-review-branch`.
- User asks to review a specific PR by number → use `review` (the built-in PR review skill) or `gh pr view`.
- User asks for a security audit → use `security-review`.
- There are no uncommitted changes (`git status` is clean) → tell the user the working tree is clean and stop. Don't fabricate findings.

## NEVER

- Never commit, amend, reset, push, or rebase.
- Never stage your fixes.
- Never review committed or branch-wide changes in this skill.
- Never run scripts that don't exist in `package.json`.
- Never run a `format` script that mutates files (no `--check` flag) — that would corrupt the user's staged baseline.
- Never invent lint output. If a check wasn't run, don't include a tool-output section for it.
