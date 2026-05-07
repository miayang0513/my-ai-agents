---
name: code-review-branch
description: Review the entire current branch against its base (default `main`) — every commit on the branch plus any uncommitted local work — as a pre-PR full-branch audit. Use when the user wants their whole branch reviewed before opening a PR or merging, asks to "review my branch", "review before I open the PR", "code review this branch vs main/develop", "audit my feature branch", or wants the multi-commit diff (not just unstaged hunks) checked. Produces summary + severity-tagged issues + action items + lint/format output, then applies fixes as unstaged edits so the user's original work stays cleanly separated in `git diff --cached`.
---

# Code Review: Branch vs Base

Full-branch review covering every commit on the current branch since it diverged from the base, plus any uncommitted local work. This is the pre-PR audit — use it when the user wants the whole branch checked, not just pending hunks.

## NEVER

- **Never run `git commit`.** The user commits after reviewing your changes.
- **Never stage your fixes.** The user's existing work stays staged; your edits stay unstaged so `git diff` shows a clean separation.
- **Never fabricate tool output.** Only paste output from checks you actually ran. If the repo has no supported check scripts, omit the tool-output section entirely.
- **Never invent a base branch.** Confirm `main` exists; if not, ask which base to use (`develop`, `master`, release branch, etc.) before diffing.

## Procedure

### 1. Determine the base branch

Default to `main`. Verify it exists locally (`git rev-parse --verify main`). If not, check for `develop` / `master` / the branch's upstream tracking base, and confirm with the user before continuing. Record which base you used — it goes in the report.

### 2. Run repo checks (only those that exist)

Inspect the project's package manifest and run only check-scripts that are actually defined. Capture full stdout/stderr verbatim for the report.

- **Node (`package.json` → `scripts`)**: detect the package manager from the lockfile (`pnpm-lock.yaml` → `pnpm`, `yarn.lock` → `yarn`, `bun.lockb` → `bun`, else `npm`). Run only:
  - `lint` if defined
  - `format:check` if defined
  - `format` only if its command is check-only (contains `--check`, `--list-different`, or the word `check`); skip if it would rewrite files
  - `typecheck` / `tsc` if defined
- **Python (`pyproject.toml`, `tox.ini`, `Makefile`)**: run configured `ruff`, `mypy`, `black --check`, etc., only if already wired up.
- **Other ecosystems**: run analogous read-only checks (e.g. `cargo clippy`, `go vet`) only if the project already configures them.

Do not install tooling. Do not run write-mode formatters. Do not run the full test suite unless the user explicitly asks.

### 3. Stage everything, then capture both diffs

```
git add -A
git diff --cached            # the user's work (committed-soon + currently-unstaged)
git diff <base>...HEAD       # everything this branch added vs base (multi-commit branch diff)
```

From this point on, treat the staged tree as **the user's work**. Any edit you make in step 5 must remain **unstaged** so it shows up clearly in `git diff` (working tree vs index).

Note the `...` (three-dot) syntax on the branch diff — it compares HEAD against the merge-base with `<base>`, which is what you want for "what this branch changed". Two-dot would include base-branch movement and is wrong here.

### 4. Write the review report

Open with one line stating the base branch and the two diffs you reviewed:

> Reviewed: `git diff --cached` (staged) and `git diff main...HEAD` (branch vs main).

Then:

- **Summary** — 2-5 bullets describing the branch's overall change set. Think PR description, not commit log.
- **Issues** — for each, give: severity (`blocker` / `major` / `minor` / `nit`), file path with line range, short description, concrete fix or strategy. Apply project conventions from `CLAUDE.md`, `.cursor/rules/`, `.editorconfig`, and any style configs you find — use them to inform review, don't restate them.
- **Positive notes** (optional) — patterns worth keeping or repeating elsewhere.
- **Action items** — what the user must do before merging (verify behavior X, add test Y, confirm Z with PM/design, rebase, squash, etc.).
- **Tool output** — verbatim stdout/stderr per executed check. Omit the section if no checks ran.

Severity calibration: `blocker` = must fix before merge (bugs, regressions, security, broken types). `major` = should fix (design issues, missing tests for new logic). `minor` = should fix if cheap. `nit` = optional polish.

### 5. Apply fixes — leave them unstaged

Fix every Issue you listed and every warning/error from the check tools you ran. Constraints:

- Match existing import style and module conventions (check `.cursor/rules/`, `tsconfig` paths, existing files in the same package).
- If the project separates types from constants/values (or has similar layering rules), respect that — move things to the right file and update imports.
- Stay surgical. Don't refactor adjacent code that wasn't in scope. Don't reformat untouched files.
- **Do not `git add` your fixes.** Final state: user's original work staged, your improvements visible as unstaged modifications.

End by telling the user how to inspect:

```
git diff             # your unstaged improvements
git diff --cached    # their original staged work
```

## Distinction from `code-review`

`code-review` reviews **only pending changes** (uncommitted/unstaged hunks) — fast loop while working. `code-review-branch` reviews the **whole branch vs base** including all committed history on the branch — the pre-PR audit. If the user only has unstaged edits and no branch divergence, prefer `code-review`.
