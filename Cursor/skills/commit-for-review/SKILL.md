---
name: commit-for-review
description: Commit on a dedicated review/<id> branch instead of the branch you're reviewing — derive the branch name from the current branch, switch to it, then commit, so your review changes never touch the branch under review. Same message/staging/hook/secret rules as the `commit` skill; only the destination branch differs. Use when reviewing a teammate's branch and you want your fixes or notes isolated on their own branch. Triggers: "commit for review", "commit this for review", "review commit", "commit on a review branch", or invoking /commit-for-review.
disable-model-invocation: true
allowed-tools: Bash(git status:*) Bash(git diff:*) Bash(git log:*) Bash(git add:*) Bash(git commit:*) Bash(git restore:*) Bash(git rev-parse:*) Bash(git switch:*) Bash(git branch:*)
---

# Commit for review

**This skill is the `commit` skill with exactly one behavioral change: the commit lands on a derived `review/<id>` branch, never on the branch under review.** Everything else — drafting a Conventional Commit from `git log` tone, choosing the smallest coherent scope, secret/lock-file/hook handling, "draft is the default, commit only when explicitly asked" — follow the `commit` skill unchanged. This file documents *only* the delta: which branch the commit goes to, and the one extra step to get there.

## Why isolate on a review branch

Reviewing a teammate's feature branch, you often need to add a fix, a test, or a note. Committing on *their* branch rewrites what you're reviewing, muddies their history, and can't be pushed cleanly. Landing your commit on `review/<id>` — branched from the tip you're reviewing — keeps their branch pristine and makes your review changes independently reviewable and easy to discard.

## Derive the review branch

From the current branch (`git rev-parse --abbrev-ref HEAD`):

| Current branch          | Target            | Rule                                    |
| ----------------------- | ----------------- | --------------------------------------- |
| `review/…` (already)    | *itself*          | Stay put — commit here.                 |
| `feat/TASK-001`         | `review/TASK-001` | `review/` + everything after first `/`. |
| `feat/TASK-001-add-login` | `review/TASK-001-add-login` | Keeps the human-readable tail. |
| `TASK-001` (no `/`)     | `review/TASK-001` | `review/` + whole name.                 |

Split on the **first** `/`, not a ticket regex: it preserves the descriptive tail and still works for branches that carry no ticket ID (`hotfix` → `review/hotfix`).

## The one added step: switch before staging

Do this **before** `git add` — the index is shared across branches, so staging while still on the branch under review, then switching, is exactly the silent mistake this skill exists to prevent.

```
target=review/<id>
git rev-parse --verify --quiet "refs/heads/$target"   # exists?
  ├─ yes → git switch "$target"        # add your commit on top
  └─ no  → git switch -c "$target"      # branches from current HEAD:
                                        #   review branch = reviewed work + your commit
git rev-parse --abbrev-ref HEAD        # MUST equal $target before you stage
```

`git switch` carries your uncommitted changes across. If it **fails** because local changes would be overwritten, **stop and report** — do not force, stash, or reset to get past it unless the user asks.

## Hard rules (added to all of `commit`'s hard rules)

- **NEVER** run `git add` or `git commit` until `git rev-parse --abbrev-ref HEAD` confirms you're on `review/<id>`. Committing on the branch under review is the one failure this skill must never produce.
- **NEVER** recreate, reset, or force an existing `review/<id>` — switch to it and add the commit on top.
- **NEVER** force a switch, stash, or reset to escape a conflicting switch — surface it and let the user decide.
- **NEVER** rename, amend, or commit on the branch under review itself.
- All of `commit`'s hard rules still apply verbatim — no `Co-Authored-By`, no `git push`, no `--no-verify`, no amending a commit you didn't author, no reverting unrelated worktree changes.

## Edge cases

- **Second `commit-for-review` for the same task** — `review/<id>` already exists. Expected: switch to it, commit on top. Never recreate.
- **`review/<id>` exists but the branch under review has advanced past it** — a plain `git switch` puts you on the *old* review tip, so your commit no longer sits on top of the current reviewed code. Flag the divergence (`git log --oneline <id-branch> ^review/<id>` shows what's missing) and confirm with the user before committing rather than silently committing on a stale base.
- **Draft-only mode (the default)** — drafting changes nothing on disk. Do **not** switch branches until the user explicitly asks to commit.
- **Detached HEAD, or mid-merge/rebase/cherry-pick** — resolve per the `commit` skill's guidance first; only then derive and switch.

## Commit flow (delta over `commit`)

When the user explicitly asks to commit:

1. Derive `review/<id>` and switch to it (create if absent); **verify with `git rev-parse --abbrev-ref HEAD`** before staging.
2. Stage → commit → confirm clean tree, exactly as the `commit` skill prescribes.
3. Report the commit hash, subject, **and the `review/<id>` branch it landed on**.
