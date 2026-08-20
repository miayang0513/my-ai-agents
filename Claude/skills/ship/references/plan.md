# Phase 2 — Bind to files → `plan.md`, then stop

Goal: `plan.md` binds every requirement in the spec to the files it changes, under the project's own conventions — then the flow **stops** for the user to read it.

## Read the project first

Before proposing an approach, read the repo's `CLAUDE.md` and `.claude/rules/` deliberately — path-scoped rules only auto-load once you touch a matching file, which is too late for planning. Directory conventions are the most common thing a generic mental model gets wrong; the repo's own docs and existing code are the authority.

Then locate where the change lands. Read the actual files you intend to bind — a plan written from directory names alone binds to the wrong place.

## Write `plan.md`

```markdown
# <id> — plan

## Binding
- "<requirement>" → <file(s)> *(assumption: …)*

## Approach
<the change, in the repo's own terms — which components, which module, which API>

## Cross-cutting
<generated code to regenerate, contracts/schemas to update first, copy/i18n
 that lives elsewhere — "none" if nothing>

## Verification
<what "done" looks like — observable outcomes, not a restatement of the
 approach. The review phase hands this to a cold-context reviewer as the
 standard to judge the diff against.>
```

For anything ambiguous, state the assumption inline so the user can correct it without re-reading the source ticket.

## Stop — or offer the fast path

Set `Status: planned`. Summarize (what changes, where, anything unresolved) and **stop**. Implementation is the next invocation, after the user has read the plan.

**Fast path** — offer it only when the task is genuinely trivial: a one-file copy/style tweak, an already-located one-line fix, or pure investigation. Say so, and on the user's yes implement directly in the main working tree, skipping the worktree/review machinery. Still write `spec.md` (it is what makes the task recallable); skip `plan.md`. Anything touching contracts, new routes/pages, or more than a couple of files always goes through the full flow.
