# Phase 1 — Intake + grill → `spec.md`

Goal: a resolved requirement the user has confirmed, written to `.claude/tasks/<id>/spec.md`.

## Intake

The requirement arrives one of two ways:

- **A ticket** (URL or id). Fetch it into *this* context by the cheapest path that works: a project-provided fetch script or command first (check the project's `CLAUDE.md` and `.claude/scripts/`), then a matching MCP connector, then `WebFetch` for public pages. Get the title, the full body, **and the comments** — on trackers, comments routinely amend the body after it was written. Never delegate the fetch to a subagent (the content would land in its context, not yours) and never infer requirements from the URL slug.
  - If comments exist, list them numbered (author, date, one-line summary) and ask which still apply. Selected comments + body = the requirement; **when they conflict, comments win.**
  - On auth failures, stop and ask the user to fix access or paste the content — the same credential fails the same way on retry.
- **Direct input.** The user's message is the requirement; go straight to the grill.

If a design link (Figma etc.) accompanies the requirement, fetch it now with the matching MCP tools; save screenshots to `.claude/tasks/<id>/assets/`.

**Task id**: the ticket's id if it has one (`TASK-3131`, `PROJ-42`, `#123` → `issue-123`); otherwise a short kebab slug. If `.claude/tasks/<id>/` already exists, read it first — this may be a second pass. Update, don't overwrite.

## Grill

Interview the user until the requirement is solid. Map it as a **design tree**: every decision branches into the decisions that hang off it. (Pattern adapted from `grill-me` at aihero.dev/skills.)

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled — the questions you can ask *now* without guessing at unheard answers. Ask the whole frontier in one round, numbered, each with your recommended answer:

```
❓ **Q1 — <title>**: <question, options if useful>
➡️ <your recommended answer>
```

Then wait. Each round of answers reshapes the tree; recompute the frontier and ask the next round. A question that depends on another question still open this round belongs to a later round.

**Facts are your job, decisions are the user's.** When a frontier question needs a fact from the environment (does the codebase already have X? what does the API return?), look it up yourself — dispatch a subagent for anything non-trivial and ask the rest of the frontier while it runs. Never ask the user for anything you could look up.

**Scale depth to the task:**

| Task shape | Depth |
| --- | --- |
| Small — one concern, few files, behaviour is obvious | One short round of only the questions that genuinely change the outcome; or state your assumptions and offer to skip straight to spec |
| Anything larger | Full frontier rounds until the tree is walked — nothing left silently assumed |

The user can end the grill at any time ("夠了", "enough, plan it"). Whatever branches were not visited become explicit entries in **Open questions** — assumptions, on the record, not silent guesses.

## Write `spec.md`

```markdown
# <id> — <short title>

- **Source**: <ticket url, or "direct input">
- **Status**: specced
- **Branch**: <filled in by the implement phase>

## Spec
<the resolved requirement = input + selected comments + grill decisions.
 Say explicitly where a comment or a grill answer overrode the original body.>

## Mockup
<design frame + `assets/<file>.png`, or "none">

## Open questions
- <unvisited branches, carried as assumptions — or "none">
```

Open questions are about the *requirement*. Fixed facts of the project's environment (things its `CLAUDE.md` already settles) do not belong there — writing them down reads as "undecided" when they are not.

Then continue to `references/plan.md` in the same run.
