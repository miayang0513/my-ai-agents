# Phase 4 — Independent review + tests → fix → stop

Goal: the diff judged against the intent recorded *before* implementation, findings fixed or rebutted, all of it on the record in `review.md`.

## Spawn the verifiers — one message, concurrently

The reviewers must be cold contexts. Swapping in fresh agents is not enough on its own — feeding them the implementer's summary makes them verify the implementer's interpretation. Give each exactly:

- the **Spec** section of `spec.md` and the **Verification** section of `plan.md`,
- the worktree path and the branch diff command: `git -C <worktree> diff origin/<base>...HEAD` (three dots — the diff against the merge base), plus `--stat` for orientation,
- the repo's `CLAUDE.md` / `.claude/rules/` paths.

**Not** `changes.md`, and **not** any implementing agent's report.

| Agent | Question it answers |
| --- | --- |
| `code-reviewer` | Does the diff satisfy the Verification criteria? Anything in the spec not implemented? Anything implemented the spec did not ask for? Convention violations? |
| `security-reviewer` | Injection, authz, secrets, unsafe input handling in the changed surface |
| `qa-engineer` — when the change touches test-covered code or names runtime behaviour | Actually run the relevant test commands **in the worktree** and report output verbatim |

They answer independent questions and none writes to the tree — spawn all applicable ones in a single message.

## Record, then act on the findings

Write all findings to `review.md` **verbatim in substance** — never soften or filter a finding because you implemented the thing it criticises. Head the file with the verdict and the criteria it was judged against.

Do not hand the user a list to triage — fix, then report what was found *and* what you did:

| Severity | Default |
| --- | --- |
| `blocker`, `major`, any confirmed security finding | **Fix, always.** No asking first. |
| `minor` | Default is fix; one that is taste, or argues for scope the plan did not bind, is not. |
| `nit` | Fix if it is a one-liner in code you already touched; otherwise leave it. |

Two overrides:

- **A finding you believe is wrong does not get "fixed" to make it go away.** Say why it is wrong, in `review.md`, and leave the code.
- **A fix needing scope `plan.md` did not bind is not yours to make.** Record it; new scope goes back through the spec phase.

Fixes land as further commits on the same branch (`fix(<id>): …`) — the squash merge collapses them. **Do not re-run the reviewer on the fixed tree**: the second verdict would be judging work the first one shaped, and would replace the only honest record. `review.md` keeps the original findings; append `## Fixes applied` — per finding: severity, what changed (or why it did not), the commit.

## Stop

Set `Status: reviewed`. Report: branch, what changed, each verdict, what you fixed in response, anything left unresolved. Then **stop** — landing is the user's explicit call (`/ship land`), never an automatic next step, and never something to ask about in the report.
