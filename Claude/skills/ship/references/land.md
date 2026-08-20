# Phase 5 — Land: env write-back → rebase → verify → squash merge → cleanup

Only entered on the user's explicit ask. Re-runnable: a landing that stopped half-way (blocked PR, failed check) is finished by running it again.

## Preflight

- `review.md` carries a fail verdict or unresolved blocker/major findings → say so and **ask before continuing**. Merging over a failed review is the user's call to make explicitly.
- Worktree dirty → stop and ask. Offer to commit on the branch (implement-phase rules apply). Never discard, never stash silently.

## 1 — Write env additions back to the main checkout

Before anything else, diff every `.env*` file between the worktree and the main checkout:

- Key exists in the worktree but not in the main checkout → **append it** to the main checkout's file (with any comment line above it).
- Same key, different value → **ask** which wins; never overwrite silently.

Do this first — once the worktree is removed, additions made there are gone.

## 2 — Rebase onto the current base

```bash
git -C <worktree> fetch origin --prune
git -C <worktree> rebase origin/<base>
```

Conflicts: one file at a time, read *both* sides, keep both intents. Unsure which side is right, or the changes are semantically incompatible → **stop and ask** — never `-X ours`/`-X theirs`. Anything goes wrong: `git rebase --abort` restores the exact pre-rebase state; reach for it instead of improvising.

## 3 — Verify the rebased branch

Integration is what breaks, not the branch in isolation. Run the project's own checks in the worktree — its `CLAUDE.md` first, else the obvious scripts (`lint`, `typecheck`, `test`, `build`) from its package manifest. Re-install first if the lockfile moved in the rebase. Red → fix on the branch and commit, or stop and report. **Never merge a branch that fails its checks.**

## 4 — Squash merge, by what the project has

Read the host, don't assume: `git -C <worktree> remote get-url origin`. The project's `CLAUDE.md` overrides all of this.

**GitHub remote + `gh`:**
```bash
git -C <worktree> push -u origin <branch>   # --force-with-lease if rebasing an already-pushed branch
gh pr create --base <base> --head <branch> --title "<type>(<id>): summary" --body "<what / why / how verified>"
gh pr merge --squash --delete-branch
```

**GitLab remote + `glab`:** same shape with `glab mr create --squash-before-merge --remove-source-branch --yes` then `glab mr merge --squash --remove-source-branch --yes` (the flag at merge is what squashes — pass both).

**No remote, or no PR flow:** local squash from the main checkout:
```bash
git switch <base> && git pull --ff-only   # skip the pull when there is no remote
git merge --squash <branch>
git commit -m "<type>(<id>): the task's one-line story"
git push                                   # only if a remote exists
```

The squash subject is the task's one-line story, not a list of WIP commits; link the source ticket in the PR body. Push rejected → someone else pushed; **stop and ask, never `--force`.** Blocked by required reviews or failing checks → that is the protection working: report the URL, leave the worktree in place, stop.

## 5 — Sync, clean up, record

1. Main checkout: `git fetch origin --prune`, `git switch <base>`, `git pull --ff-only`. A refused fast-forward means local commits or a diverged base — stop and ask.
2. Confirm the squash landed on the base (the PR reports merged, or the squash commit is on `<base>`), then:
   ```bash
   git worktree remove .worktrees/<id>
   git branch -D <branch>       # only after the landing is confirmed — after a squash, -d always refuses
   ```
   `worktree remove` refusing (dirty tree) is information — never `--force` without the user's explicit yes.
3. Append to `changes.md` under Commits: the PR/MR URL (or local squash hash) and the squash commit. Set `Status: landed`.

## Report

Branch and squash commit (with URL), env keys written back, worktree and branch removed — or exactly what is still open and why. Then stop.
