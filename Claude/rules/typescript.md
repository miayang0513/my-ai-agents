---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---

# TypeScript

Conventions for any TypeScript file. Extracted from prior agent stack defaults so they apply when the main agent edits TS too — not just when a subagent is dispatched.

- **No `any`.** Use `unknown` and narrow before use. If a third-party type forces it, isolate to one cast site.
- **Prefer `type` over `interface`.** Use `interface` only when extending multiple types or augmenting a third-party declaration.
- **Use `satisfies`** to enforce conformity without losing literal-type information.
- **Constrain generics meaningfully.** `T extends Record<string, unknown>` beats `T extends any`. Default-type params (`<T = string>`) when there's a sensible fallback.
- **Validate untrusted input at the boundary** (Zod / Valibot / equivalent). Trust internal callers' types — don't double-validate inside service code.
- **Deterministic error envelopes** at API boundaries. Same shape, same fields, every endpoint. Don't leak SQL fragments, stack traces, or internal IDs to clients.
- **Type signatures, not bodies.** Type the function event/context/return at the signature; don't cast inside the body.
- **Share request/response DTOs** between server and client. Let the type system enforce the contract instead of hand-syncing two definitions.

Conflicts with project conventions → project wins.
