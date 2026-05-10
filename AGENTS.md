# AGENTS.md

Repository-level guidance for AI agents and human contributors.

## Purpose

This repo has two distributions of the same operating model:

- `Claude/` — Claude-native setup
- `Cursor/` — Cursor-native setup

Keep behavior parity between them whenever practical.

## Source of truth

- Claude edition content is the primary source for policy/rules/role intent.
- Cursor edition should stay semantically aligned, but may differ where runtime capabilities differ.
- Use `NON_CLAUDE_PARITY_PLAN.md` for migration decisions and parity constraints.

## Editing rules

- Make minimal, surgical edits tied to the requested outcome.
- Do not mix unrelated refactors with migration changes.
- Preserve existing file structure and naming conventions.
- Keep code/comments/docs in English.

## Documentation structure

- Root `README.md` is a router only.
- Edition-specific docs live in:
  - `Claude/README.md`
  - `Cursor/README.md`
- Detailed setup steps remain in each edition's `setup.md`.

## Parity expectations

When adding/changing capabilities in one edition, check whether the other edition needs:

1. equivalent behavior
2. explicit fallback
3. documented limitation

If exact parity is not possible, document the reason in the edition README or setup doc.

## Scripts and safety

- Avoid destructive shell operations in repo scripts unless explicitly required.
- Keep guard logic strict by default (false positives are acceptable; secret leaks are not).
- Prefer configurable adapters over provider-specific hardcoding.

## Agent/rule/skill updates

- If `Claude/agents`, `Claude/rules`, or `Claude/skills` change, verify whether `Cursor/` equivalents must also be updated.
- Keep tool names/provider namespaces runtime-appropriate for each edition.

## Validation checklist (for substantive changes)

- docs updated in the correct edition
- parity impact reviewed
- bootstrap scripts still work
- no obvious secret exposure in synced files
