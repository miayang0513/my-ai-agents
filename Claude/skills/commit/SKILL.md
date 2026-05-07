---
name: commit
description: Inspect git changes, draft a Conventional Commit message, and create the commit when explicitly asked. Use when the user says commit, asks for a commit message, wants to stage and commit, asks to review a diff before committing, or types phrases like "commit this", "write a commit message", "prepare a commit".
disable-model-invocation: true
allowed-tools: Bash(git status:*) Bash(git diff:*) Bash(git log:*) Bash(git add:*) Bash(git commit:*) Bash(git restore:*)
---

# Commit

Prepare a Conventional Commit message for the current working tree, then create the commit only when the user explicitly asks for it.

## Default workflow

1. Run `git status`, `git diff`, `git diff --cached`, and `git log -n 5 --oneline` to see the working tree, what's staged, and recent message style.
2. If nothing is staged but there are unstaged changes, stage them with `git add -A` and re-check `git diff --cached`. If there are no changes at all, say so and stop.
3. Pick the smallest coherent scope. If the diff spans unrelated areas (e.g. app + infra, src + generated output), call it out and propose splitting before committing.
4. Choose a Conventional Commit type: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `build`, `ci`, `perf`, `style`.
5. Draft the message focused on intent and impact, matching the repo's existing tone (check `git log`).
6. Surface anything the user should review before committing — secrets, unrelated files, generated/lock-file noise, large binary additions.

## Message format

```
type(scope): short summary

optional body
```

- Lowercase type and scope.
- Summary is specific and concrete; no filler ("update stuff", "various changes").
- Body only when it clarifies *why* or flags a tradeoff. Skip it otherwise.
- One logical change per commit.
- Add a ticket prefix (e.g. `TASK-123`) only if the repo's history already does.

## Modes

**Draft only** (default — assume this unless the user says "commit"):

> Suggested commit message:
> ```
> type(scope): short summary
>
> optional body
> ```
> Then list anything to exclude or verify.

**Create the commit** (only when the user explicitly says commit / "commit it" / "go ahead"):

1. Stage the intended files (be specific — prefer `git add <paths>` over `git add -A` when only some files belong).
2. `git commit -m "<message>"` using a heredoc for multi-line bodies.
3. Run `git status` to confirm the tree is clean.
4. Report the resulting commit hash and subject.

## Hard rules

- **Never** add a `Co-Authored-By: Claude …` trailer or any "made with" attribution. The user's global rule forbids it.
- **Never** commit unless the user explicitly asked. Drafting is the default.
- **Never** include `.env`, credentials, tokens, or other likely secrets. If the user insists, warn first.
- **Never** rewrite history (`--amend`, `rebase`, `reset --hard`) unless explicitly requested. If a hook fails, fix the cause and create a new commit.
- **Never** revert unrelated changes in the worktree — commit only the intended files and leave the rest alone.
- **Never** push. `git push` is a separate, explicit request.
- **Never** use `-i` flags (interactive rebase/add); they break in this environment.
- **Never** skip hooks (`--no-verify`) or signing flags unless the user explicitly asks.

## Repo-specific checks

Before committing, glance at the repo for lint/format/typecheck scripts (`package.json`, `Makefile`, `pyproject.toml`, CI config). If a fast check exists and the diff plausibly affects it, run it. Don't run slow full builds or test suites unless asked.
