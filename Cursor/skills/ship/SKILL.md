---
name: ship
description: "End-to-end feature flow for any repo: requirement intake (ticket URL or direct input) → grill interview → spec + plan → implementation on a feature branch in a git worktree → code review + security review + tests → rebase, squash merge, worktree cleanup. Invoke as `/ship <ticket-url or requirement>` to start a task, `/ship` to resume the one in flight, `/ship land` to merge a finished one. Project conventions always override this skill's generic defaults."
disable-model-invocation: true
---

# Ship — requirement to merged

A re-entrant state machine. Each task lives in `.cursor/tasks/<id>/` in the current repo; the `Status` line in its `spec.md` says where the flow stands, and every invocation routes from it. Phases are described in `references/` — **read only the file(s) for the phase you are entering**, not all of them.

```
.cursor/tasks/<id>/
  spec.md      ← what to build (Status line lives here)
  plan.md      ← how to build it (file bindings + verification criteria)
  changes.md   ← what was changed, where, on which branch
  review.md    ← the independent verdicts, verbatim, plus fixes applied
```

Keep `.cursor/tasks/` and `.worktrees/` out of the team's git: if the repo's `.gitignore` does not already cover them, add both to `.git/info/exclude` (local-only) — never edit a shared `.gitignore` for this.

## Dispatch

| Invocation | Status in `spec.md` | Do |
| --- | --- | --- |
| `/ship <url or requirement>` | (new task) | `references/spec.md`, then `references/plan.md` → **stop** |
| `/ship` | `planned` | `references/implement.md`, then `references/review.md` → **stop** |
| `/ship land` (or an equally explicit ask) | `reviewed` | `references/land.md` |
| `/ship` | anything else | resume inside the phase that status belongs to |

Bare `/ship` with more than one task open (`Status` ≠ `landed`): list them and ask which. Exactly one open: continue it, saying so.

The two stops are the point: after **plan** (a misread requirement costs two documents, not a branch of work) and after **review** (merging is the user's explicit call, never an automatic next step). Do not roll through them.

## Status values

`specced → planned → implemented → reviewed → landed`. Update the line as each phase completes — a crashed session resumes from it.

## Project adapter

This skill carries **generic defaults only**. Before each phase, the current project's own `CLAUDE.md` and `.cursor/rules/` win for: ticket source and fetch method, base branch, directory conventions, verification commands, merge policy. If the project ships its own flow skills (e.g. a multi-repo workspace with its own worktree tooling), use those and treat this skill as unavailable there.

## Never

- **NEVER edit the main checkout during implementation** — all edits go to the task's worktree. The main checkout stays on the base branch and stays clean.
- **NEVER push, open a PR, or merge outside the land phase**, and never enter that phase without the user explicitly asking for it.
- **NEVER proceed on a partial ticket fetch** — a gap in a spec is invisible, which makes it worse than no spec. Ask the user to fix access or paste the content.
- **NEVER give a reviewer the implementer's account of the work** — reviewers judge the diff against the spec written *before* implementation.
- **NEVER write code before `plan.md` exists** (except the fast path in `references/plan.md`, which the user accepts explicitly).
- **NEVER commit on the base branch** — the worktree branch is the only place this flow commits.
