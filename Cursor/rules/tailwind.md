---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/tailwind.config.{ts,js,mjs}"
  - "**/globals.css"
  - "**/tailwind.css"
---

# Tailwind

Conventions for Tailwind utility usage in JSX/CSS files.

- **Mobile-first.** Default styles target the smallest screen; `sm: md: lg:` modifiers add up. No `max-*:` flipping.
- **Logical properties over directional ones.** `inset-*`, `start/end`, `block/inline` for i18n / RTL safety. Avoid hard-coded `left/right` unless the design is genuinely directional.
- **`clsx` / `cva` for dynamic class composition.** No template-string concatenation of class names — breaks the JIT scanner and produces unstyled output.
- **Avoid `@apply` outside a dedicated CSS file** (`tailwind.css`, `globals.css`). The contract is utilities-in-JSX; pulling them into a custom class hides the styling from where it's used.
- **Pair semantic HTML with utilities.** `<button>`, `<nav>`, `<section>`, `<article>`, etc. Utilities don't substitute for semantics or a11y attributes.
- **No custom CSS for what utilities cover.** If you're writing more than ~5 lines of bespoke CSS, check whether existing utilities (or `@layer components`) handle it.

Conflicts with project conventions → project wins.
