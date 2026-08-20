# Phase 3 — Worktree + feature branch → implement → commit

Goal: the plan implemented and committed on an isolated branch, recorded in `changes.md`. Nothing pushed, nothing merged — that is the land phase.

The isolation is the point: the main checkout stays on the base branch and stays clean, and several tasks can be in flight without sharing a working tree.

## Provision the worktree

1. **Base branch**: the project's `CLAUDE.md` if it names one; else `origin/develop` if it exists; else the remote HEAD (`git remote show origin`). Fetch first: `git fetch origin --prune`.
2. **Branch name**: `<type>/<id>-<slug>` — `type` is `feat`/`fix`/`chore`, `slug` 2–4 lowercase-kebab English words.
3. **Cut it**:
   ```bash
   git worktree add .worktrees/<id> -b <type>/<id>-<slug> origin/<base> --no-track
   ```
   (If the project ships its own worktree tooling, use that instead — it likely handles things this generic recipe doesn't.)
4. **Copy ignored env files** into the worktree — they don't travel with git:
   ```bash
   git ls-files --others --ignored --exclude-standard | grep -E '(^|/)\.env'
   ```
   copy each listed file to the same relative path under `.worktrees/<id>/`. The land phase diffs these back, so additions made inside the worktree are not lost.
5. **Install dependencies** in the worktree, by lockfile (`pnpm-lock.yaml` → `pnpm install`, `package-lock.json` → `npm ci`, `yarn.lock` → `yarn`, `uv.lock` → `uv sync`, …). Init submodules if the repo has them.

Record the branch in `spec.md`'s `Branch:` line. **From here every path is inside the worktree** — `.worktrees/<id>/…`, never the repo root. Getting this wrong is the single easiest mistake in this flow.

## Size it, then implement

Delegation is not free — a subagent is a cold context that re-reads the repo before writing a line. Decide first:

| | Direct — implement in main context | Delegated — role subagent implements |
| --- | --- | --- |
| Scope | plan binds ≤3 files | anything larger |
| Kind | copy / styling / located bug fix / field added to an existing shape | new route or page, new component tree, contract or schema change, migration |

When in doubt, go direct — escalating mid-way is cheap; a wasted agent run is not.

**Delegated path**: pick the role matching the area (`frontend-engineer`, `backend-engineer`, `devops-engineer`). Hand the agent the **absolute worktree path** (every edit goes there), the **full text** of `spec.md` and `plan.md` (not a summary — the bindings are the instructions), a pointer to the repo's `CLAUDE.md` and rules, and the constraint: *implement only what the plan binds; do not commit, push, or merge.* Independent areas → separate agents in a single message, run concurrently; ordered dependencies (contract → codegen → consumer) stay sequential.

## Commit, then record

Per the worktree: read `git -C <worktree> status --short` and the diff, check nothing unwanted is caught (`.env*`, build output, anything unrelated), then commit:

```
<type>(<id>): short summary in the imperative
```

Conventional Commits, English, matching the repo's own log. If a pre-commit hook reformats and aborts, re-stage and commit again — never `--amend`, never `--no-verify`. **Do not push.**

Write `changes.md`:

```markdown
# <id> — changes

- **Branch**: <type>/<id>-<slug>  **Worktree**: `.worktrees/<id>`

## Changes
- `<file>` — <what changed and why>

## Deviations from plan
- <anything done differently, and why — or "none">

## Commits
- `<hash>` — <subject>
```

**Deviations is the section that matters** — an unexplained difference from the plan is what the reviewer will flag. Set `Status: implemented` and continue to `references/review.md` in the same run.
