---
name: commit
description: Inspect git changes, draft a Conventional Commit message, and create the commit when explicitly asked — staging only the paths this session produced, never the whole worktree. Use when the user says commit, asks for a commit message, wants to stage and commit, asks to review a diff before committing, or types phrases like "commit this", "write a commit message", "prepare a commit".
disable-model-invocation: true
allowed-tools: Bash(git status:*) Bash(git diff:*) Bash(git log:*) Bash(git add:*) Bash(git commit:*) Bash(git restore:*)
---

# Commit

Prepare a Conventional Commit message for the current working tree, then create the commit only when the user explicitly asks for it.

## Default workflow

**Branch first:** if the user supplied a draft message, you're *editing* it (preserve their voice and intent; only fix Conventional-Commit shape and obvious issues). If they didn't, draft from scratch.

1. Read state: `git status`, `git diff`, `git diff --cached`, `git log -n 5 --oneline`.
2. Work out which paths *this session* produced (see **Session scope**) and stage only those, by explicit path. Re-check `git diff --cached`. If the tree is clean, say so and stop.
3. Pick the smallest coherent scope. If the diff spans unrelated areas (app + infra, src + generated output, multiple features), call it out and propose splitting before committing.
4. Draft the message focused on *intent and impact*, not file enumeration.
5. Surface anything to review before committing — secrets, unrelated files, lock-file noise, large binary additions, generated output.

## Session scope

Commit only what this session produced. Everything else in the worktree is the user's own work-in-progress and stays untouched — a `commit` request is never a request to sweep the tree.

**The authority is your own record of what you changed** — every `Edit`/`Write` you made, plus any file a command you ran created, moved, or generated. Not `git status`. A dirty file you never touched is pre-existing work, however related it looks.

- Stage by explicit path: `git add -- <path> [<path>…]`. Never `git add -A`, `git add .`, or `git commit -a`.
- Files you created are untracked — they need an explicit `git add` or they'll be left behind.
- **A file you edited can still carry changes that aren't yours.** `git add <file>` stages the *whole file*, so if it was already dirty before you touched it, staging by path silently commits the user's in-progress work too. Use `git add -p` to take only your hunks, or surface it and let the user decide.
- Content staged *before* you were invoked is the user's deliberate staging. Don't unstage it, but don't quietly fold it into your message either — report it and ask whether it belongs in this commit.
- **If you can't reconstruct what you touched** — resumed or compacted session, or the user edited files by hand alongside you — say so and ask which paths to stage. Don't guess, and never fall back to staging everything.

After staging, list the paths going in, and name anything dirty you deliberately left out so the user can see the split.

## Message format

`git log -n 5 --oneline` is the spec, not Conventional Commits canon. Match the existing tone — many repos drop scope, some require a ticket prefix (`TASK-123:`), some use sentence-case bodies, some prefix with package names instead of types. Deviate from CC when the log does.

- Body only when it clarifies *why* or flags a tradeoff. Skip it otherwise.
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

1. Stage this session's paths explicitly — `git add -- <paths>` (see **Session scope**). Never `-A`.
2. `git commit -m "<message>"` using a heredoc for multi-line bodies.
3. Run `git status` to confirm the tree is clean.
4. Report the resulting commit hash and subject.

## Hard rules

- **Never** add a `Co-Authored-By: Claude …` trailer or any "made with" attribution. The user's global rule forbids it.
- **Never** commit unless the user explicitly asked. Drafting is the default.
- **Never** include `.env`, credentials, tokens, or other likely secrets. If the user insists, warn first.
- **Never** `--amend` a commit you didn't author yourself (check `git log -1 --format='%an'` first). Amending another author's commit silently rewrites their work.
- **Never** rewrite history (`--amend`, `rebase`, `reset --hard`) unless explicitly requested. If a hook fails, fix the cause and create a new commit.
- **Never** blindly re-run `git commit` after a hook rewrites files. Re-run `git diff --cached` first — verify the now-staged tree is what you intended before retrying.
- **Never** `git add -A`, `git add .`, or `git commit -a` — each sweeps in worktree changes this session didn't make.
- **Never** revert unrelated changes in the worktree — commit only the intended files and leave the rest alone.
- **Never** push. `git push` is a separate, explicit request.
- **Never** use `-i` flags (interactive rebase/add); they break in this environment.
- **Never** skip hooks (`--no-verify`) or signing flags unless the user explicitly asks.

## Common scenarios

- **Pre-commit hook reformats files mid-commit.** The commit aborts with a dirty tree. Re-stage the now-formatted files and run `git commit` again — do *not* `--amend` (the previous commit isn't yours) and do *not* `--no-verify`.
- **Pre-commit fails on staged files but the user wants to commit a subset.** Use `git add -p` to split hunks; commit the clean subset first, leave the failing changes unstaged for the user to address.
- **Merge / cherry-pick / rebase in progress.** `git status` shows files in *both modified* or `.git/MERGE_HEAD` exists. Finish the resolution first (`git add` each resolved file, run the build/typecheck if cheap), then commit. Never `--allow-empty` past a conflict, never reset to "make it go away" — that destroys the resolution.
- **Amend or squash workflow.** Only when the user explicitly asks. For HEAD use `git commit --amend`; for older commits use `git commit --fixup=<sha>` then `git rebase -i --autosquash <base>`. Refuse if the target commit has already been pushed to a shared branch — surface the risk and let the user decide.
- **Monorepo with per-package lint/format.** Check `pnpm-workspace.yaml`, `nx.json`, `lerna.json`, or `turbo.json` first to find the affected package, then run scripts from that package's directory — running root-level scripts often misses or duplicates work.
- **Worktree was already dirty when the session started.** Normal — the user has parallel work in flight. Stage only your paths, commit, and list what you left dirty. Don't offer to "clean up" the rest.
- **User provided a draft message.** Edit, don't replace. Preserve their voice, phrasing, and emphasis. Fix only the Conventional-Commit shape (type, scope, casing) and obvious issues (typos, wrong type). If their message is already fine, say so and use it verbatim.

## Repo-specific checks

Before committing, glance at the repo for lint/format/typecheck scripts (`package.json`, `Makefile`, `pyproject.toml`, CI config). If a fast check exists and the diff plausibly affects it, run it. Don't run slow full builds or test suites unless asked.
